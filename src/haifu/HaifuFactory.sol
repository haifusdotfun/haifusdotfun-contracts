// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.24;

import {Haifu, IHaifu} from "./Haifu.sol";
import {CloneFactory} from "../libraries/CloneFactory.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IHaifu} from "../interfaces/IHaifu.sol";

interface IERC20 {
    function symbol() external view returns (string memory);
}

contract HaifuFactory is  Initializable {
    // Orderbooks
    address[] public allHaifus;
    /// Address of manager
    address public override launchpad;
    /// version number of impl
    uint32 public version;
    /// address of order impl
    address public impl;
    /// listing cost of pair, for each fee token.
    mapping(address => uint256) public listingCosts;

    error InvalidAccess(address sender, address allowed);
    error HaifuAlreadyExists(address base, address quote, address pair);
    error SameBaseQuote(address base, address quote);

    constructor() {}

    function createHaifu(
        IHaifu.State memory haifu
    ) external override returns (address orderbook) {
        if (msg.sender != engine) {
            revert InvalidAccess(msg.sender, engine);
        }

        address haifu = _predictAddress(haifu.name, haifu.symbol, haifu.creator);

        // Check if the address has code
        uint32 size;
        assembly {
            size := extcodesize(pair)
        }

        // If the address has code and it's a clone of impl, revert.
        if (size > 0 || CloneFactory._isClone(impl, pair)) {
            revert PairAlreadyExists(base_, quote_, pair);
        }

        address proxy = CloneFactory._createCloneWithSalt(
            impl,
            _getSalt(base_, quote_)
        );
        IHaifu(proxy).initialize(allPairsLength(), base_, quote_, engine);
        allPairs.push(proxy);
        return (proxy);
    }

    function isClone(address vault) external view returns (bool cloned) {
        cloned = CloneFactory._isClone(impl, vault);
    }

    /**
     * @dev Initialize orderbook factory contract with engine address, reinitialize if engine is reset.
     * @param engine_ The address of the engine contract
     * @return address of pair implementation contract
     */
    function initialize(address engine_) public initializer returns (address) {
        engine = engine_;
        _createImpl();
        return impl;
    }

    function allHaifusLength() public view returns (uint256) {
        return allHaifus.length;
    }

    // Set immutable, consistant, one rule for orderbook implementation
    function _createImpl() internal {
        address addr;
        bytes memory bytecode = type(Haifu).creationCode;
        bytes32 salt = keccak256(abi.encodePacked("haifu", version));
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        impl = addr;
    }

    function _predictAddress(
        string name,
        string symbol,
        address creator
    ) internal view returns (address) {
        bytes32 salt = _getSalt(name, symbol, creator);
        return CloneFactory.predictAddressWithSalt(address(this), impl, salt);
    }

    function _getSalt(
        string name,
        string symbol,
        address creator
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name, symbol, creator));
    }

    function getByteCode() external view returns (bytes memory bytecode) {
        return CloneFactory.getBytecode(impl);
    }
}
