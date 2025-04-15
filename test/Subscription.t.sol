// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {AggregatorV3Interface, TokenRegistry} from "../contracts/TokenRegistry.sol";
import {Subscription} from "../contracts/Subscription.sol";

contract SubscriptionTest is Test {
    using SafeERC20 for IERC20;
    using MessageHashUtils for bytes32;

    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 WETH = IERC20(0x4200000000000000000000000000000000000006);
    IERC20 WBTC = IERC20(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);
    IERC20 GEMS = IERC20(0x3010ccb5419F1EF26D40a7cd3F0d707a0fa127Dc);
    IERC20 ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address user = 0x12eF0F1C99D8FD50fFd37cCd12B09Ef7f1213269;
    address owner = 0x3B764564639032F61fdA5360727577A4CbCe75cB;
    address funds = 0xC0FC8954c62A45c3c0a13813Bd2A10d88D70750D;

    Subscription public subscriptionContract;
    address signer;
    uint256 privateKey;

    uint256 subscriptionFee = 400e6;

    function setUp() public {
        // ----------------------------------- Signer  ----------------------------------- //

        privateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
        signer = vm.addr(privateKey);

        // -----------------------------------  deal ----------------------------------- //
        deal(user, 8000000 * 1e18);
        deal(funds, 8000000 * 1e18);

        deal(address(GEMS), user, 8000000 * 1e18);
        deal(address(GEMS), funds, 8000000 * 1e18);

        deal(address(USDT), user, 4000 * 1e6);
        deal(address(USDT), funds, 4000 * 1e6);

        // -----------------------------------  Contract ----------------------------------- //
        subscriptionContract = new Subscription(
            funds,
            signer,
            owner,
            subscriptionFee
        );

        // -----------------------------------  price feed ----------------------------------- //

        vm.startPrank(owner);
        TokenRegistry.PriceFeedData[]
            memory priceFeedData = new TokenRegistry.PriceFeedData[](2);
        priceFeedData[0] = TokenRegistry.PriceFeedData({
            priceFeed: AggregatorV3Interface(
                0x3E7d1eAB13ad0104d2750B8863b489D65364e32D
            ),
            normalizationFactorForToken: 8,
            tolerance: 172800
        });
        priceFeedData[1] = TokenRegistry.PriceFeedData({
            priceFeed: AggregatorV3Interface(
                0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            ),
            normalizationFactorForToken: 20,
            tolerance: 7200
        });

        IERC20[] memory tok = new IERC20[](2);
        tok[0] = IERC20(USDT);
        tok[1] = IERC20(ETH);

        subscriptionContract.setTokenPriceFeed(tok, priceFeedData);
        vm.stopPrank();

        // -----------------------------------  Allowed tokens ----------------------------------- //

        vm.startPrank(owner);

        IERC20[] memory tokens = new IERC20[](4);
        tokens[0] = IERC20(ETH);
        tokens[1] = USDT;
        tokens[2] = USDC;
        tokens[3] = GEMS;

        bool[] memory accesses = new bool[](4);
        accesses[0] = true;
        accesses[1] = true;
        accesses[2] = true;
        accesses[3] = true;

        subscriptionContract.updateAllowedTokens(tokens, accesses);
        vm.stopPrank();
    }

    // -----------------------------------  tests ----------------------------------- //

    function testSubscriptionWithETH() external {
        uint256 expectedWalletFunds;
        uint256 prevWalletFunds;
        uint256 fee;

        uint256 deadline = block.timestamp;

        uint256 price = 392522046;
        uint8 nf = 22;
        //sign
        (uint8 v, bytes32 r, bytes32 s) = _validateSignWithETH(deadline);

        //previous balance
        prevWalletFunds = GEMS.balanceOf(subscriptionContract.fundsWallet());

        //calaculating nft purchasing amount
        fee = subscriptionContract.subscriptionFee();
        expectedWalletFunds = (fee * (10 ** nf)) / price;

        //node buying
        vm.startPrank(user);
        USDT.forceApprove(address(subscriptionContract), USDT.balanceOf(user));
        subscriptionContract.subscribeWithETH{value: 0.3 ether}(
            deadline,
            v,
            r,
            s
        );
        console.log("time is===", subscriptionContract.subEndTimes(user));
        vm.stopPrank();
        // vm.warp(block.timestamp + 3600);

        // (uint8 v1, bytes32 r1, bytes32 s1) = _validateSignWithToken(
        //     price,
        //     nf,
        //     GEMS,
        //     block.timestamp
        // );

        // subscriptionContract.subscribe(
        //     GEMS,
        //     price,
        //     block.timestamp,
        //     nf,
        //     v1,
        //     r1,
        //     s1
        // );
        // vm.stopPrank();

        // //wallet balance assertion
        // assertEq(
        //     GEMS.balanceOf(subscriptionContract.fundsWallet()) -
        //         prevWalletFunds,
        //     expectedWalletFunds,
        //     "Subscription Wallet Funds"
        // );
    }

    function testSubscriptionWithUSDT() external {
        uint256 expectedWalletFunds;
        uint256 prevWalletFunds;
        uint256 fee;

        uint256 deadline = block.timestamp;

        uint256 price = 392522046;
        uint8 nf = 22;
        //sign
        (uint8 v, bytes32 r, bytes32 s) = _validateSignWithToken(
            0,
            0,
            USDT,
            deadline
        );

        //previous balance
        prevWalletFunds = GEMS.balanceOf(subscriptionContract.fundsWallet());

        //calaculating nft purchasing amount
        fee = subscriptionContract.subscriptionFee();
        expectedWalletFunds = (fee * (10 ** nf)) / price;

        //node buying
        vm.startPrank(user);
        USDT.forceApprove(address(subscriptionContract), USDT.balanceOf(user));
        subscriptionContract.subscribeWithToken(USDT, 0, deadline, 0, v, r, s);
        console.log("time is===", subscriptionContract.subEndTimes(user));
        vm.stopPrank();
        // vm.warp(block.timestamp + 3600);

        // (uint8 v1, bytes32 r1, bytes32 s1) = _validateSignWithToken(
        //     price,
        //     nf,
        //     GEMS,
        //     block.timestamp
        // );

        // subscriptionContract.subscribe(
        //     GEMS,
        //     price,
        //     block.timestamp,
        //     nf,
        //     v1,
        //     r1,
        //     s1
        // );
        // vm.stopPrank();

        // //wallet balance assertion
        // assertEq(
        //     GEMS.balanceOf(subscriptionContract.fundsWallet()) -
        //         prevWalletFunds,
        //     expectedWalletFunds,
        //     "Subscription Wallet Funds"
        // );
    }

    function testSubscriptionWithGEMS() external {
        uint256 expectedWalletFunds;
        uint256 prevWalletFunds;
        uint256 fee;

        uint256 deadline = block.timestamp;

        uint256 price = 1500000000;
        uint8 nf = 22;
        //sign
        (uint8 v, bytes32 r, bytes32 s) = _validateSignWithToken(
            price,
            nf,
            GEMS,
            deadline
        );

        //previous balance
        prevWalletFunds = GEMS.balanceOf(subscriptionContract.fundsWallet());

        //calaculating nft purchasing amount
        fee = subscriptionContract.subscriptionFee();
        expectedWalletFunds = (fee * (10 ** nf)) / price;

        //node buying
        vm.startPrank(user);
        GEMS.forceApprove(address(subscriptionContract), GEMS.balanceOf(user));
        subscriptionContract.subscribeWithToken(
            GEMS,
            price,
            deadline,
            nf,
            v,
            r,
            s
        );
        console.log("time is===", subscriptionContract.subEndTimes(user));
        vm.stopPrank();
        // vm.warp(block.timestamp + 3600);

        // (uint8 v1, bytes32 r1, bytes32 s1) = _validateSignWithToken(
        //     price,
        //     nf,
        //     GEMS,
        //     block.timestamp
        // );

        // subscriptionContract.subscribe(
        //     GEMS,
        //     price,
        //     block.timestamp,
        //     nf,
        //     v1,
        //     r1,
        //     s1
        // );
        // vm.stopPrank();

        // //wallet balance assertion
        // assertEq(
        //     GEMS.balanceOf(subscriptionContract.fundsWallet()) -
        //         prevWalletFunds,
        //     expectedWalletFunds,
        //     "Subscription Wallet Funds"
        // );
    }

    // -----------------------------------  Helping function ----------------------------------- //
    function _validateSignWithToken(
        uint256 referenceTokenPrice,
        uint256 normalizationFactor,
        IERC20 token,
        uint256 deadline
    ) private returns (uint8, bytes32, bytes32) {
        vm.startPrank(signer);
        bytes32 msgHash = (
            keccak256(
                abi.encodePacked(
                    user,
                    uint8(normalizationFactor),
                    uint256(referenceTokenPrice),
                    deadline,
                    token
                )
            )
        ).toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        vm.stopPrank();
        return (v, r, s);
    }

    function _validateSignWithETH(
        uint256 deadline
    ) private returns (uint8, bytes32, bytes32) {
        vm.startPrank(signer);
        bytes32 msgHash = (keccak256(abi.encodePacked(user, deadline, ETH)))
            .toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        vm.stopPrank();
        return (v, r, s);
    }
}
