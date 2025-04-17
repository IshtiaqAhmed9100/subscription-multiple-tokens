// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.25;
// import {Test, console} from "../lib/forge-std/src/Test.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// import {AggregatorV3Interface, TokenRegistry} from "../contracts/TokenRegistry.sol";
// import {Subscription} from "../contracts/Subscription.sol";

// contract SubscriptionTest is Test {
//     using SafeERC20 for IERC20;
//     using MessageHashUtils for bytes32;

//     IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
//     IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
//     IERC20 WETH = IERC20(0x4200000000000000000000000000000000000006);
//     IERC20 WBTC = IERC20(0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf);
//     IERC20 GEMS = IERC20(0x3010ccb5419F1EF26D40a7cd3F0d707a0fa127Dc);
//     IERC20 ETH = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

//     IERC20 DOP = IERC20(0xa048E46C35cf210bB0d5bb46b2DD06828Ef17893);

//     address user = 0x12eF0F1C99D8FD50fFd37cCd12B09Ef7f1213269;
//     address owner = 0x3B764564639032F61fdA5360727577A4CbCe75cB;
//     address funds = 0xC0FC8954c62A45c3c0a13813Bd2A10d88D70750D;

//     Subscription public subscriptionContract;
//     address signer;
//     uint256 privateKey;

//     uint256 subscriptionFee = 400e6;

//     function setUp() public {
//         // ----------------------------------- Signer  ----------------------------------- //

//         privateKey = vm.envUint("PRIVATE_KEY_SEPOLIA");
//         signer = vm.addr(privateKey);

//         // -----------------------------------  Contract ----------------------------------- //
//         subscriptionContract = Subscription(
//             0xba5503D9742514cAA55F7289303684f992bE7aEC
//         );
//         //     funds,
//         //     signer,
//         //     owner,
//         //     subscriptionFee
//         // );
//     }

//     // -----------------------------------  tests ----------------------------------- //

//     function testSubscriptionWithGEMS() external {
//         //node buying
//         vm.startPrank(0x128a4A208B8D38aC5e256F3Cbdd6766870fa7034);

//         // GEMS.forceApprove(address(subscriptionContract), GEMS.balanceOf(user));
//         // vm.warp(8130402);
//         subscriptionContract.subscribeWithToken(
//             DOP,
//             3103413,
//             1744808701,
//             22,
//             28,
//             0x3398e3c4409619b98c100a0396f8e675a46cc72b9fbcb9919150a6fb621e5505,
//             0x20b64805e59a0a70570e501aa6060c8bea60e9b11a5ea62e8392b0f6b971ff56
//         );
//         console.log("time is===", subscriptionContract.subEndTimes(user));
//         vm.stopPrank();

//         // vm.warp(block.timestamp + 3600);

//         // (uint8 v1, bytes32 r1, bytes32 s1) = _validateSignWithToken(
//         //     price,
//         //     nf,
//         //     GEMS,
//         //     block.timestamp
//         // );

//         // subscriptionContract.subscribe(
//         //     GEMS,
//         //     price,
//         //     block.timestamp,
//         //     nf,
//         //     v1,
//         //     r1,
//         //     s1
//         // );
//         // vm.stopPrank();

//         // //wallet balance assertion
//         // assertEq(
//         //     GEMS.balanceOf(subscriptionContract.fundsWallet()) -
//         //         prevWalletFunds,
//         //     expectedWalletFunds,
//         //     "Subscription Wallet Funds"
//         // );
//     }

//     // -----------------------------------  Helping function ----------------------------------- //
//     function _validateSignWithToken(
//         uint256 referenceTokenPrice,
//         uint256 normalizationFactor,
//         IERC20 token,
//         uint256 deadline
//     ) private returns (uint8, bytes32, bytes32) {
//         vm.startPrank(signer);
//         bytes32 msgHash = (
//             keccak256(
//                 abi.encodePacked(
//                     user,
//                     uint8(normalizationFactor),
//                     uint256(referenceTokenPrice),
//                     deadline,
//                     token
//                 )
//             )
//         ).toEthSignedMessageHash();
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
//         vm.stopPrank();
//         return (v, r, s);
//     }

//     function _validateSignWithETH(
//         uint256 deadline
//     ) private returns (uint8, bytes32, bytes32) {
//         vm.startPrank(signer);
//         bytes32 msgHash = (keccak256(abi.encodePacked(user, deadline, ETH)))
//             .toEthSignedMessageHash();
//         (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
//         vm.stopPrank();
//         return (v, r, s);
//     }
// }
