// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ReentrancyGuardTransient} from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {TokenRegistry} from "../contracts/TokenRegistry.sol";

import {ETH, ZeroAddress, ZeroLengthArray, IdenticalValue, ArrayLengthMismatch, InvalidSignature} from "../contracts/utils/Common.sol";

/// @title Subscription contract
/// @notice Implements the functionality of purchasing premium subscription
/// @notice The subscription contract allows you to get premium subscription using allowed tokens.
contract Subscription is Ownable2Step, ReentrancyGuardTransient, TokenRegistry {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /// @member price The price of token from price feed
    /// @member normalizationFactorForToken The normalization factor to achieve return value of desired decimals, while calculation & always with different token decimals
    struct TokenInfo {
        uint256 latestPrice;
        uint8 normalizationFactorForToken;
    }

    /// @dev The constant value helps in calculating subscription time for each index
    uint256 public SUBSCRIPTION_TIME = 600;

    /// @notice The subscription fee in USD
    uint256 public subscriptionFee;

    /// @notice The address of the signer wallet
    address public signerWallet;

    /// @notice The address of the funds wallet
    address public fundsWallet;

    /// @notice That buyEnabled or not
    bool public buyEnabled = true;

    /// @notice Gives info about address's permission
    mapping(address => bool) public blacklistAddress;

    /// @notice Stores the end time of the user's subscription
    mapping(address => uint256) public subEndTimes;

    /// @notice mapping gives us access info of the token
    mapping(IERC20 => bool) public allowedTokens;

    /// @dev Emitted when address of signer is updated
    event SignerUpdated(address oldSigner, address newSigner);

    /// @dev Emitted when address of funds wallet is updated
    event fundsWalletUpdated(address oldfundsWallet, address newfundsWallet);

    /// @dev Emitted when blacklist access of address is updated
    event BlacklistUpdated(address which, bool accessNow);

    /// @dev Emitted when buying access changes
    event BuyEnableUpdated(bool oldAccess, bool newAccess);

    /// @dev Emitted when subscription fee is updated
    event SubscriptionFeeUpdated(uint256 oldFee, uint256 newFee);

    /// @dev Emitted when subscription is purchased
    event Subscribed(
        IERC20 token,
        uint256 tokenPrice,
        address indexed by,
        uint256 amountPurchased,
        uint256 indexed endTime
    );

    /// @dev Emitted when token access is updated
    event TokensAccessUpdated(IERC20 indexed token, bool indexed access);

    /// @notice Thrown when address is blacklisted
    error Blacklisted();

    /// @notice Thrown when buy is disabled
    error BuyNotEnabled();

    /// @notice Thrown when sign deadline is expired
    error DeadlineExpired();

    /// @notice Thrown when value is zero
    error ZeroValue();

    /// @notice Thrown when user have already have subscription
    error AlreadySubscribed();

    /// @notice Thrown if the roundId of price is not updated
    error RoundIdNotUpdated();

    /// @notice Thrown if the price is not updated
    error PriceNotUpdated();

    /// @notice Thrown when both price feed and reference price are non zero
    error CodeSyncIssue();

    /// @notice Thrown when price from price feed returns zero
    error PriceNotFound();

    /// @notice Thrown when Token is not allowed
    error TokenDisallowed();

    /// @dev Restricts when updating wallet/contract address with zero address
    modifier checkAddressZero(address which) {
        _checkAddressZero(which);
        _;
    }

    /// @dev Constructor
    /// @param fundsWalletAddress The address of funds wallet
    /// @param signerAddress The address of signer wallet
    /// @param owner The address of owner wallet
    /// @param subscriptionFeeInit The subscription fee in USD
    constructor(
        address fundsWalletAddress,
        address signerAddress,
        address owner,
        uint256 subscriptionFeeInit
    )
        Ownable(owner)
        checkAddressZero(fundsWalletAddress)
        checkAddressZero(signerAddress)
    {
        if (subscriptionFeeInit == 0) {
            revert ZeroValue();
        }

        fundsWallet = fundsWalletAddress;
        signerWallet = signerAddress;
        subscriptionFee = subscriptionFeeInit;
    }

    /// @notice Purchases the premium subscription with ETH
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function subscribeWithETH(
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable nonReentrant {
        _validatePurchase(ETH, deadline);
        _verifyPurchaseWithETH(deadline, v, r, s);

        TokenInfo memory tokenInfo = getLatestPrice(ETH);

        if (tokenInfo.latestPrice == 0) {
            revert PriceNotFound();
        }

        uint256 purchaseAmount = (subscriptionFee *
            (10 ** tokenInfo.normalizationFactorForToken)) /
            tokenInfo.latestPrice;

        if (purchaseAmount == 0) {
            revert ZeroValue();
        }

        uint256 amountUnused = msg.value - purchaseAmount;

        if (amountUnused > 0) {
            payable(msg.sender).sendValue(amountUnused);
        }

        payable(fundsWallet).sendValue(purchaseAmount);
        subEndTimes[msg.sender] = block.timestamp + SUBSCRIPTION_TIME;

        emit Subscribed({
            token: ETH,
            tokenPrice: tokenInfo.latestPrice,
            by: msg.sender,
            amountPurchased: purchaseAmount,
            endTime: subEndTimes[msg.sender]
        });
    }

    /// @notice Purchases the premium subscription with any allowed token
    /// @param token The token to purchase subscription
    /// @param referenceTokenPrice The current price of token in 10 decimals
    /// @param deadline The deadline is validity of the signature
    /// @param referenceNormalizationFactor The normalization factor
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function subscribeWithToken(
        IERC20 token,
        uint256 referenceTokenPrice,
        uint256 deadline,
        uint8 referenceNormalizationFactor,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        _validatePurchase(token, deadline);
        _verifyPurchaseWithToken(
            token,
            deadline,
            referenceTokenPrice,
            referenceNormalizationFactor,
            v,
            r,
            s
        );

        (uint256 latestPrice, uint8 normalizationFactor) = _validatePrice(
            token,
            referenceTokenPrice,
            referenceNormalizationFactor
        );

        uint256 purchaseAmount = (subscriptionFee *
            (10 ** normalizationFactor)) / latestPrice;

        if (purchaseAmount == 0) {
            revert ZeroValue();
        }

        token.safeTransferFrom(msg.sender, fundsWallet, purchaseAmount);
        subEndTimes[msg.sender] = block.timestamp + SUBSCRIPTION_TIME;

        emit Subscribed({
            token: token,
            tokenPrice: latestPrice,
            by: msg.sender,
            amountPurchased: purchaseAmount,
            endTime: subEndTimes[msg.sender]
        });
    }

    /// @notice Updates the access of tokens
    /// @param tokens addresses of the tokens
    /// @param accesses The access for the tokens
    function updateAllowedTokens(
        IERC20[] calldata tokens,
        bool[] calldata accesses
    ) external onlyOwner {
        uint256 tokensLength = tokens.length;

        if (tokensLength == 0) {
            revert ZeroLengthArray();
        }

        if (tokensLength != accesses.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < tokensLength; ++i) {
            IERC20 token = tokens[i];
            bool access = accesses[i];

            if (address(token) == address(0)) {
                revert ZeroAddress();
            }

            allowedTokens[token] = access;

            emit TokensAccessUpdated({token: token, access: access});
        }
    }

    /// @notice Changes access of buying
    /// @param enabled The decision about buying
    function enableBuy(bool enabled) external onlyOwner {
        if (buyEnabled == enabled) {
            revert IdenticalValue();
        }

        emit BuyEnableUpdated({oldAccess: buyEnabled, newAccess: enabled});

        buyEnabled = enabled;
    }

    /// @notice Changes signer wallet address
    /// @param newSigner The address of the new signer wallet
    function changeSigner(
        address newSigner
    ) external checkAddressZero(newSigner) onlyOwner {
        address oldSigner = signerWallet;

        if (oldSigner == newSigner) {
            revert IdenticalValue();
        }

        emit SignerUpdated({oldSigner: oldSigner, newSigner: newSigner});

        signerWallet = newSigner;
    }

    /// @notice Changes node funds wallet address
    /// @param newfundsWallet The address of the new funds wallet
    function updatefundsWallet(
        address newfundsWallet
    ) external checkAddressZero(newfundsWallet) onlyOwner {
        address oldfundsWallet = fundsWallet;

        if (oldfundsWallet == newfundsWallet) {
            revert IdenticalValue();
        }

        emit fundsWalletUpdated({
            oldfundsWallet: oldfundsWallet,
            newfundsWallet: newfundsWallet
        });

        fundsWallet = newfundsWallet;
    }

    /// @notice Changes the subscription fee
    /// @param newFee The new subscription fee
    function updateSubscriptionFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = subscriptionFee;

        if (newFee == oldFee) {
            revert IdenticalValue();
        }

        if (newFee == 0) {
            revert ZeroValue();
        }

        emit SubscriptionFeeUpdated({oldFee: oldFee, newFee: newFee});

        subscriptionFee = newFee;
    }

    /// @notice Changes the access of any address in contract interaction
    /// @param which The address for which access is updated
    /// @param access The access decision of `which` address
    function updateBlackListedUser(
        address which,
        bool access
    ) external checkAddressZero(which) onlyOwner {
        bool oldAccess = blacklistAddress[which];

        if (oldAccess == access) {
            revert IdenticalValue();
        }

        emit BlacklistUpdated({which: which, accessNow: access});

        blacklistAddress[which] = access;
    }

    /// @dev Checks zero address, if zero then reverts
    /// @param which The `which` address to check for zero address
    function _checkAddressZero(address which) private pure {
        if (which == address(0)) {
            revert ZeroAddress();
        }
    }

    /// @dev Provides us live price of token from price feed or returns reference price and reverts if price is zero
    function _validatePrice(
        IERC20 token,
        uint256 referenceTokenPrice,
        uint8 referenceNormalizationFactor
    ) private view returns (uint256, uint8) {
        TokenInfo memory tokenInfo = getLatestPrice(token);
        if (tokenInfo.latestPrice != 0) {
            if (referenceTokenPrice != 0 || referenceNormalizationFactor != 0) {
                revert CodeSyncIssue();
            }
        }
        //  If price feed isn't available,we fallback to the reference price
        if (tokenInfo.latestPrice == 0) {
            if (referenceTokenPrice == 0 || referenceNormalizationFactor == 0) {
                revert ZeroValue();
            }

            tokenInfo.latestPrice = referenceTokenPrice;
            tokenInfo
                .normalizationFactorForToken = referenceNormalizationFactor;
        }

        return (tokenInfo.latestPrice, tokenInfo.normalizationFactorForToken);
    }

    /// @notice The Chainlink inherited function, give us tokens live price
    function getLatestPrice(
        IERC20 token
    ) public view returns (TokenInfo memory) {
        PriceFeedData memory data = tokenData[token];
        TokenInfo memory tokenInfo;

        if (address(data.priceFeed) == address(0)) {
            return tokenInfo;
        }
        (
            uint80 roundId,
            /*uint80 roundID*/ int price /*uint256 startedAt*/ /*uint80 answeredInRound*/,
            ,
            uint256 updatedAt,

        ) = /*uint256 timeStamp*/ data.priceFeed.latestRoundData();

        if (roundId == 0) {
            revert RoundIdNotUpdated();
        }

        if (updatedAt == 0 || block.timestamp - updatedAt > data.tolerance) {
            revert PriceNotUpdated();
        }

        return
            TokenInfo({
                latestPrice: uint256(price),
                normalizationFactorForToken: data.normalizationFactorForToken
            });
    }

    /// @dev Validates purchase
    function _validatePurchase(IERC20 token, uint256 deadline) private view {
        if (!buyEnabled) {
            revert BuyNotEnabled();
        }

        if (blacklistAddress[msg.sender]) {
            revert Blacklisted();
        }

        if (block.timestamp > deadline) {
            revert DeadlineExpired();
        }

        if (!allowedTokens[token]) {
            revert TokenDisallowed();
        }

        if (subEndTimes[msg.sender] > block.timestamp) {
            revert AlreadySubscribed();
        }
    }

    /// @dev Verifies signature with eth
    function _verifyPurchaseWithETH(
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        if (
            signerWallet !=
            ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(
                    keccak256(abi.encodePacked(msg.sender, deadline, ETH))
                ),
                v,
                r,
                s
            )
        ) {
            revert InvalidSignature();
        }
    }

    /// @dev Verifies signature with given token
    function _verifyPurchaseWithToken(
        IERC20 token,
        uint256 deadline,
        uint256 referenceTokenPrice,
        uint8 normalizationFactor,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private view {
        if (
            signerWallet !=
            ECDSA.recover(
                MessageHashUtils.toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            msg.sender,
                            normalizationFactor,
                            referenceTokenPrice,
                            deadline,
                            token
                        )
                    )
                ),
                v,
                r,
                s
            )
        ) {
            revert InvalidSignature();
        }
    }

    function updateSubscriptionTime(uint256 newTime) external onlyOwner {
        SUBSCRIPTION_TIME = newTime;
    }
}
