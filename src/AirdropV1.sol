// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Proton} from "./token/proton.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirdropV1 is Ownable {
    using SafeERC20 for IERC20;

    error AirdropV1__MismatchedLength();
    error AirdropV1__InvalidClaimer();
    error AirdropV1__UserHasClaimed();

    IERC20 private immutable proton;
    mapping(address => uint256) public claimerToAmount;
    mapping(address => bool) public hasClaimed;

    constructor(IERC20 _proton) Ownable(msg.sender) {
        proton = _proton;
    }

    function addClaimer(address[] memory claimers, uint256[] memory amount) external onlyOwner {
        if (claimers.length != amount.length) {
            revert AirdropV1__MismatchedLength();
        }

        uint256 i = 0;
        for (; i < claimers.length;) {
            claimerToAmount[claimers[i]] = amount[i];
            unchecked {
                ++i;
            }
        }
    }

    function claimAirdrop() external {
        address caller = msg.sender;
        if (claimerToAmount[caller] == 0) {
            revert AirdropV1__InvalidClaimer();
        }

        if (hasClaimed[caller]) {
            revert AirdropV1__UserHasClaimed();
        }

        hasClaimed[caller] = true;
        proton.safeTransfer(caller, claimerToAmount[caller]);
    }

    function getProton() external view returns (address) {
        return address(proton);
    }
}
