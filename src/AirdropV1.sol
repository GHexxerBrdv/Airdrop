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
    error AirdropV1__ClaimerAlreadyExist();
    error AirdropV1__DeadlinePassedToClaim();

    IERC20 private immutable proton;
    mapping(address => uint256) public claimerToAmount;
    mapping(address => bool) public hasClaimed;
    uint256 s_deadline;

    event AirdropClaimed(address claimer, uint256 amount);
    event ClaimersAdded();
    event ClaimerRemoved(address claimer);

    constructor(IERC20 _proton, uint256 deadline) Ownable(msg.sender) {
        proton = _proton;
        s_deadline = block.timestamp + (deadline * 1 days);
    }

    function addClaimer(address[] memory claimers, uint256[] memory amount) external onlyOwner {
        if (claimers.length != amount.length) {
            revert AirdropV1__MismatchedLength();
        }
        uint256 i = 0;
        for (; i < claimers.length;) {
            if (claimerToAmount[claimers[i]] > 0) {
                revert AirdropV1__ClaimerAlreadyExist();
            }
            claimerToAmount[claimers[i]] = amount[i];
            unchecked {
                ++i;
            }
        }

        emit ClaimersAdded();
    }

    function claimAirdrop() external {
        if (block.timestamp > s_deadline) {
            revert AirdropV1__DeadlinePassedToClaim();
        }
        address caller = msg.sender;
        if (claimerToAmount[caller] == 0) {
            revert AirdropV1__InvalidClaimer();
        }

        if (hasClaimed[caller]) {
            revert AirdropV1__UserHasClaimed();
        }

        uint256 amount = claimerToAmount[caller];
        hasClaimed[caller] = true;
        claimerToAmount[caller] = 0;
        proton.safeTransfer(caller, amount);

        emit AirdropClaimed(caller, amount);
    }

    function removeClaimer(address _claimer) external onlyOwner {
        delete claimerToAmount[_claimer];
        emit ClaimerRemoved(_claimer);
    }

    function getProton() external view returns (address) {
        return address(proton);
    }
}
