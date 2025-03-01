// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {wAIfu, IHaifu} from "./wAIfu.sol";
import {CloneFactory} from "../libraries/CloneFactory.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IHaifu} from "../interfaces/IHaifu.sol";

interface IERC20 {
    function symbol() external view returns (string memory);
}

contract wAIfuFactory is Initializable {
    // Orderbooks
    address[] public allwAIfus;
    /// Address of manager
    address public wAIfuManager;
    /// Address of matching engine
    address public matchingEngine;
    /// version number of impl
    uint32 public version;
    /// address of order impl
    address public impl;
    /// listing cost of pair, for each fee token.
    mapping(address => uint256) public listingCosts;

    error InvalidAccess(address sender, address allowed);
    error wAIfuAlreadyExists(string name, string symbol, address creator);

    constructor() {}

    function createHaifu(string memory name, string memory symbol, address creator, IHaifu.State memory wAIfuInfo)
        external
        returns (address wAIfu)
    {
        if (msg.sender != wAIfuManager) {
            revert InvalidAccess(msg.sender, wAIfuManager);
        }

        wAIfu = _predictAddress(name, symbol, creator);

        // Check if the address has code
        uint32 size;
        assembly {
            size := extcodesize(wAIfu)
        }

        // If the address has code and it's a clone of impl, revert.
        if (size > 0 || CloneFactory._isClone(impl, wAIfu)) {
            revert wAIfuAlreadyExists(name, symbol, creator);
        }

        wAIfu = CloneFactory._createCloneWithSalt(impl, _getSalt(name, symbol, creator));
        IHaifu(wAIfu).initialize(name, symbol, matchingEngine, wAIfuManager, creator, wAIfuInfo);
        allwAIfus.push(wAIfu);
        return (wAIfu);
    }

    function isClone(address vault) external view returns (bool cloned) {
        cloned = CloneFactory._isClone(impl, vault);
    }

    /**
     * @dev Initialize orderbook factory contract with engine address, reinitialize if engine is reset.
     * @param wAIfuManager_ The address of the engine contract
     * @return address of pair implementation contract
     */
    function initialize(address wAIfuManager_, address matchingEngine_) public initializer returns (address) {
        wAIfuManager = wAIfuManager_;
        matchingEngine = matchingEngine_;
        _createImpl();
        return impl;
    }

    function allwAIfusLength() public view returns (uint256) {
        return allwAIfus.length;
    }

    // Set immutable, consistant, one rule for orderbook implementation
    function _createImpl() internal {
        address addr;
        bytes memory bytecode = type(wAIfu).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("haifu", version));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
        impl = addr;
    }

    function _predictAddress(string memory name, string memory symbol, address creator)
        internal
        view
        returns (address)
    {
        bytes32 salt = _getSalt(name, symbol, creator);
        return CloneFactory.predictAddressWithSalt(address(this), impl, salt);
    }

    function _getSalt(string memory name, string memory symbol, address creator) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, symbol, creator));
    }

    function getByteCode() external view returns (bytes memory bytecode) {
        return CloneFactory.getBytecode(impl);
    }
}
