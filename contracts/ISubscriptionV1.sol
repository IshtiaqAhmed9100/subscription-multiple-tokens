// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface ISubscriptionV1 {
    /// @notice Returns the subscription end time for the given user
    function subEndTimes(address user) external view returns (uint256 endTime);
}
