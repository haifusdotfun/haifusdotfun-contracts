// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

interface IHaifu {
    struct State {
        uint256 totalSupply;
        // carry in fraction of 1e8
        uint256 carry;
        address fundManager;
        address deposit;
        // {haifu token} / {deposit token}
        uint256 depositPrice;
        uint256 raised;
        uint256 goal;
        address HAIFU;
        // {haifu token} / {$HAIFU}
        uint256 haifuPrice;
        uint256 haifuGoal;
        uint256 haifuRaised;
        uint256 fundAcceptingExpiaryDate;
        uint256 fundExpiaryDate;
    }

    struct OrderInfo {
        uint256 makePrice;
        uint256 placed;
        uint32 orderId;
    }

    struct HaifuOpenInfo {
        address creator;
        address deposit;
        uint256 depositPrice;
        uint256 haifuPrice;
    }

    function isWhitelisted(address account) external view returns (bool);

    function openInfo() external view returns (HaifuOpenInfo memory);

    function fundAcceptingExpiaryDate() external view returns (uint256);

    function fundExpiaryDate() external view returns (uint256);

    function createHaifu(string memory name, string memory symbol, address creator, State memory haifu) external;

    function initialize(address matchingEngine, address creator, State memory haifu) external;

    function commit(address sender, address deposit, uint256 amount) external;

    function commitHaifu(address sender, uint256 amount) external;

    function withdraw(address sender, address deposit, uint256 amount) external;

    function withdrawHaifu(address sender, uint256 amount) external;

    function trackExpiary(address managingAsset, uint32 orderId) external;

    function claimExpiary(uint256 amount) external;

    function getCarry(address account, uint256 amount, bool isMaker) external view returns (uint256);

    function getHaifu(string memory name, string memory symbol, address creator)
        external
        view
        returns (State memory state);

    function getCommitted(address account) external view returns (uint256 committed);

    function deposit() external view returns (address);

    function creator() external view returns (address);

    function fundManager() external view returns (address);

    function goal() external view returns (uint256);

    function haifuCap() external view returns (uint256);

    function depositPrice() external view returns (uint256);

    function haifuPrice() external view returns (uint256);

    function launchPrice() external view returns (uint256);

    function isCapitalRaised() external view returns (bool);

    function open() external returns (uint256 leftHaifu);

    function expire(address deposit) external returns (uint256 redemptionBalance);
}
