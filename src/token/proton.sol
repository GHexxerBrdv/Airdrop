// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Proton is ERC20, Ownable, AccessControl {
    error Proton__InvalidAddressOrAmount();
    error Proton__ZeroAddress();

    bytes32 private constant MINTER = keccak256("MINTER");
    address private minterAuthority;

    constructor() ERC20("Proton", "PT") Ownable(msg.sender) {
        _grantRole(MINTER, msg.sender);
        minterAuthority = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER) returns (uint256) {
        if (to == address(0) || amount == 0) {
            revert Proton__InvalidAddressOrAmount();
        }
        _mint(to, amount);
        return amount;
    }

    function setMinterAuthority(address _minterAuthority) external onlyOwner {
        if (_minterAuthority == address(0)) {
            revert Proton__ZeroAddress();
        }
        _revokeRole(MINTER, minterAuthority);
        minterAuthority = _minterAuthority;
        _grantRole(MINTER, _minterAuthority);
    }

    function getMinterAuthority() external view returns (address) {
        return minterAuthority;
    }
}
