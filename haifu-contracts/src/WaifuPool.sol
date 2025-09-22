// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;
import {IMatchingEngine} from "standard3.0-contracts/exchange/interfaces/IMatchingEngine.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WaifuPool is AccessControl, Initializable, ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Role constants
    bytes32 public constant MARKET_MAKER_ROLE = keccak256("MARKET_MAKER_ROLE");
    bytes32 public constant LP_TOKEN_ROLE = keccak256("LP_TOKEN_ROLE");

    // Contract addresses
    address public matchingEngine;
    address public WETH;
    address public base;
    address public quote;

    // Pool state
    uint256 public totalBaseReserve;
    uint256 public totalQuoteReserve;
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    
    // ERC20 metadata override storage
    string private _tokenName;
    string private _tokenSymbol;

    // Events
    event LiquidityAdded(address indexed provider, uint256 baseAmount, uint256 quoteAmount, uint256 lpTokens);
    event LiquidityRemoved(address indexed provider, uint256 baseAmount, uint256 quoteAmount, uint256 lpTokens);

    constructor() ERC20("MM Pool LP Fund", "Fund") {
    }

    function name() public view override returns (string memory) {
        return _tokenName;
    }

    function symbol() public view override returns (string memory) {
        return _tokenSymbol;
    }

    function initialize(address _matchingEngine, address _WETH, address _base, address _quote, string memory name, string memory symbol) external initializer {
        matchingEngine = _matchingEngine;
        WETH = _WETH;
        base = _base;
        quote = _quote;
        // set name for ERC20 name and symbol from base and quote
        _tokenName = name;
        _tokenSymbol = symbol;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(LP_TOKEN_ROLE, msg.sender);
    }

    function grantMMRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MARKET_MAKER_ROLE, account);
    }

    // Market maker functions
    function createOrders(IMatchingEngine.CreateOrderInput[] memory createOrderData) external onlyRole(MARKET_MAKER_ROLE) returns (IMatchingEngine.OrderResult[] memory results) {
        // set receipient on to this contract address
        for (uint256 i = 0; i < createOrderData.length; i++) {
            createOrderData[i].recipient = address(this);
        }
        return IMatchingEngine(matchingEngine).createOrders(createOrderData);
    }

    function updateOrders(IMatchingEngine.CreateOrderInput[] memory createOrderData) external onlyRole(MARKET_MAKER_ROLE) returns (IMatchingEngine.OrderResult[] memory results) {
        // set receipient on to this contract address
        for (uint256 i = 0; i < createOrderData.length; i++) {
            createOrderData[i].recipient = address(this);
        }
        return IMatchingEngine(matchingEngine).updateOrders(createOrderData);
    }

    function cancelOrders(IMatchingEngine.CancelOrderInput[] memory cancelOrderData) external onlyRole(MARKET_MAKER_ROLE) returns (uint256[] memory refunded) {
        return IMatchingEngine(matchingEngine).cancelOrders(cancelOrderData);
    }

    // LP token functions
    function deposit(uint256 baseAmount, uint256 quoteAmount) external nonReentrant returns (uint256 lpTokens) {
        require(baseAmount > 0 && quoteAmount > 0, "Invalid deposit amounts");
        
        // Transfer tokens from user to pool
        IERC20(base).safeTransferFrom(msg.sender, address(this), baseAmount);
        IERC20(quote).safeTransferFrom(msg.sender, address(this), quoteAmount);
        
        // Calculate LP tokens to mint
        uint256 totalSupply = totalSupply();
        
        if (totalSupply == 0) {
            // First deposit - mint initial LP tokens
            lpTokens = _sqrt(baseAmount * quoteAmount);
            require(lpTokens > MINIMUM_LIQUIDITY, "Insufficient initial liquidity");
            // Burn minimum liquidity tokens to prevent rounding attacks
            _mint(address(0), MINIMUM_LIQUIDITY);
            lpTokens -= MINIMUM_LIQUIDITY;
        } else {
            // Calculate LP tokens based on proportional share
            uint256 lpFromBase = (baseAmount * totalSupply) / totalBaseReserve;
            uint256 lpFromQuote = (quoteAmount * totalSupply) / totalQuoteReserve;
            lpTokens = lpFromBase < lpFromQuote ? lpFromBase : lpFromQuote;
        }
        
        require(lpTokens > 0, "Insufficient LP tokens minted");
        
        // Update reserves
        totalBaseReserve += baseAmount;
        totalQuoteReserve += quoteAmount;
        
        // Mint LP tokens to user
        _mint(msg.sender, lpTokens);
        
        emit LiquidityAdded(msg.sender, baseAmount, quoteAmount, lpTokens);
    }

    function withdraw(uint256 lpTokens) external nonReentrant returns (uint256 baseAmount, uint256 quoteAmount) {
        require(lpTokens > 0, "Invalid LP token amount");
        require(balanceOf(msg.sender) >= lpTokens, "Insufficient LP tokens");
        
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "No liquidity");
        
        // Calculate proportional amounts to withdraw
        baseAmount = (lpTokens * totalBaseReserve) / totalSupply;
        quoteAmount = (lpTokens * totalQuoteReserve) / totalSupply;
        
        require(baseAmount > 0 && quoteAmount > 0, "Insufficient liquidity withdrawn");
        
        // Update reserves
        totalBaseReserve -= baseAmount;
        totalQuoteReserve -= quoteAmount;
        
        // Burn LP tokens
        _burn(msg.sender, lpTokens);
        
        // Transfer tokens to user
        IERC20(base).safeTransfer(msg.sender, baseAmount);
        IERC20(quote).safeTransfer(msg.sender, quoteAmount);
        
        emit LiquidityRemoved(msg.sender, baseAmount, quoteAmount, lpTokens);
    }

    function depositETH(uint256 quoteAmount) external payable nonReentrant returns (uint256 lpTokens) {
        require(msg.value > 0 && quoteAmount > 0, "Invalid deposit amounts");
        require(base == WETH, "Pool does not support ETH");
        
        // Transfer quote tokens from user to pool
        IERC20(quote).safeTransferFrom(msg.sender, address(this), quoteAmount);
        
        // Calculate LP tokens to mint
        uint256 totalSupply = totalSupply();
        uint256 baseAmount = msg.value;
        
        if (totalSupply == 0) {
            // First deposit - mint initial LP tokens
            lpTokens = _sqrt(baseAmount * quoteAmount);
            require(lpTokens > MINIMUM_LIQUIDITY, "Insufficient initial liquidity");
            // Burn minimum liquidity tokens to prevent rounding attacks
            _mint(address(0), MINIMUM_LIQUIDITY);
            lpTokens -= MINIMUM_LIQUIDITY;
        } else {
            // Calculate LP tokens based on proportional share
            uint256 lpFromBase = (baseAmount * totalSupply) / totalBaseReserve;
            uint256 lpFromQuote = (quoteAmount * totalSupply) / totalQuoteReserve;
            lpTokens = lpFromBase < lpFromQuote ? lpFromBase : lpFromQuote;
        }
        
        require(lpTokens > 0, "Insufficient LP tokens minted");
        
        // Update reserves
        totalBaseReserve += baseAmount;
        totalQuoteReserve += quoteAmount;
        
        // Mint LP tokens to user
        _mint(msg.sender, lpTokens);
        
        emit LiquidityAdded(msg.sender, baseAmount, quoteAmount, lpTokens);
    }

    function withdrawETH(uint256 lpTokens) external nonReentrant returns (uint256 baseAmount, uint256 quoteAmount) {
        require(base == WETH, "Pool does not support ETH");
        require(lpTokens > 0, "Invalid LP token amount");
        require(balanceOf(msg.sender) >= lpTokens, "Insufficient LP tokens");
        
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "No liquidity");
        
        // Calculate proportional amounts to withdraw
        baseAmount = (lpTokens * totalBaseReserve) / totalSupply;
        quoteAmount = (lpTokens * totalQuoteReserve) / totalSupply;
        
        require(baseAmount > 0 && quoteAmount > 0, "Insufficient liquidity withdrawn");
        
        // Update reserves
        totalBaseReserve -= baseAmount;
        totalQuoteReserve -= quoteAmount;
        
        // Burn LP tokens
        _burn(msg.sender, lpTokens);
        
        // Transfer tokens to user
        payable(msg.sender).transfer(baseAmount);
        IERC20(quote).safeTransfer(msg.sender, quoteAmount);
        
        emit LiquidityRemoved(msg.sender, baseAmount, quoteAmount, lpTokens);
    }

    // Internal helper function for square root calculation
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // View functions
    function getReserves() external view returns (uint256 baseReserve, uint256 quoteReserve) {
        return (totalBaseReserve, totalQuoteReserve);
    }

    function getLPTokenValue(uint256 lpTokens) external view returns (uint256 baseAmount, uint256 quoteAmount) {
        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) return (0, 0);
        
        baseAmount = (lpTokens * totalBaseReserve) / totalSupply;
        quoteAmount = (lpTokens * totalQuoteReserve) / totalSupply;
    }

    // Admin function to sync reserves with actual balances
    function syncReserves() external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalBaseReserve = IERC20(base).balanceOf(address(this));
        totalQuoteReserve = IERC20(quote).balanceOf(address(this));
        
    }

    // Function to receive ETH
    receive() external payable {
        require(base == WETH, "Pool does not support ETH");
    }
    
}