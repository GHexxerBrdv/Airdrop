// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Proton} from "./token/proton.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {AutomationCompatibleInterface} from
    "lib/chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Airdrop
 * @author Gaurang Bharadava
 * Airdrop with two phase
 * 1. private with merkle airdrop
 * 2. public airdrop
 * -> only selected user can be participate in private airdrop and with permitted user can claim airdrop onbehalf of user.
 * -> there is predefined tokens amounts for both phase
 * -> from the public phase any one can claim token at most one.
 * -> Note :- if users has failed to claim token from private phase then their amount will be added to public phase.
 */
contract AirdropV3 is Ownable, EIP712, AutomationCompatibleInterface, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    /**
     * @notice Errors to be reverted.
     */
    error AirdropV3__InvalidProof();
    error AirdropV3__UserHasAlreadyClaim(address account);
    error AirdropV3__InvalidSignature();
    error AirdropV3__InvalidArrayLength();
    error AirdropV3__OnlyClaimableInPrivatePhase();
    error AirdropV3__durationHasBeenPassed();
    error AirdropV3__CanNotChangePhase();
    error AirdropV3__OnlyClaimableInPublicPhase();
    error AirdropV3__ContractHaveNotEnoughBalance();

    /**
     * @notice State variables.
     */
    IERC20 private airdropToken;
    bytes32 private root;
    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,address permitted,uint256 amount)");

    uint256 public privatePhaseAmount;
    uint256 public publicPhaseAmount;
    uint256 public timeDuration;
    uint256 public interval;
    uint256 public lastTimestamp;

    mapping(address => bool) public hasClaimed;

    enum PHASE {
        PRIVATE,
        PUBLIC
    }

    PHASE public phase;

    struct AirdropClaim {
        address account;
        address permited;
        uint256 amount;
    }

    /**
     * @notice Modifier ensure if the phase is private or not.
     */
    modifier IfPrivate() {
        if (phase != PHASE.PRIVATE) {
            revert AirdropV3__OnlyClaimableInPrivatePhase();
        }

        if (block.timestamp > timeDuration) {
            revert AirdropV3__durationHasBeenPassed();
        }

        _;
    }

    /**
     * @notice Events to be emited.
     */
    event ClaimedAirdrop(address account, uint256 amount);
    event ClaimSkiped(address account, string message);
    event SetUpAirdrop(bytes32 root, IERC20 token, uint256 privatePhaseAmount, uint256 publicPhaseAMount);
    event AirdropIsNowPublic(uint256 timestamp);

    constructor(string memory name, string memory version) Ownable(msg.sender) EIP712(name, version) {}

    /**
     *
     * @param _root Merkle root for the airdrop, To varify the claimer.
     * @param token Token for which the airdrop want  to set
     * @param _privatePhaseAmount Amount distributed in private phase
     * @param _publicPhaseAmount Amount distributed in public phase
     * @param _duration Duration for the private phase
     */
    function setAirdrop(
        bytes32 _root,
        IERC20 token,
        uint256 _privatePhaseAmount,
        uint256 _publicPhaseAmount,
        uint256 _duration
    ) external onlyOwner {
        root = _root;
        airdropToken = token;
        phase = PHASE.PRIVATE;
        privatePhaseAmount = _privatePhaseAmount;
        publicPhaseAmount = _publicPhaseAmount;
        timeDuration = block.timestamp + (_duration * 1 minutes);
        lastTimestamp = block.timestamp;

        emit SetUpAirdrop(root, token, privatePhaseAmount, publicPhaseAmount);
    }

    /**
     * @notice This function can be called only if Airdrop in private phase.
     * @notice Proof will ensure that only intended user or whitelisted user can claim their amount of tokens.
     * @param amount Amount the user wants to claim.
     * @param proof Array of proof that verify the claimer and the amount.
     */
    function claimAirdrop(uint256 amount, bytes32[] calldata proof) external IfPrivate nonReentrant {
        address account = msg.sender;
        if (hasClaimed[account]) {
            revert AirdropV3__UserHasAlreadyClaim(account);
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(proof, root, leaf)) {
            revert AirdropV3__InvalidProof();
        }

        hasClaimed[account] = true;
        privatePhaseAmount -= amount;
        emit ClaimedAirdrop(account, amount);
        airdropToken.safeTransfer(account, amount);
    }

    /**
     * @notice Any user who is permited to claim tokens on behalf of the whitelistd claimer can call this fucntion, but they should have signature signed by the claimer.
     * @param account The account for the user wants to claim.
     * @param amount Amount for the account the user want to claim.
     * @param proof Proof to verify the whitelisted claimer and amount.
     * @notice v, r, s The component oof signature user has signed.
     */
    function claimPermit(address account, uint256 amount, bytes32[] calldata proof, uint8 v, bytes32 r, bytes32 s)
        external
        IfPrivate
        nonReentrant
    {
        address caller = msg.sender;

        if (hasClaimed[account]) {
            revert AirdropV3__UserHasAlreadyClaim(account);
        }

        if (!_verifySignature(account, _messageHash(account, caller, amount), v, r, s)) {
            revert AirdropV3__InvalidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(proof, root, leaf)) {
            revert AirdropV3__InvalidProof();
        }

        hasClaimed[account] = true;
        privatePhaseAmount -= amount;
        emit ClaimedAirdrop(account, amount);
        airdropToken.safeTransfer(account, amount);
    }

    /**
     * @notice This fucntion can only be called in public phase by anyone and calim upto one airdrop token.
     */
    function claim() external nonReentrant {
        if (phase != PHASE.PUBLIC) {
            revert AirdropV3__OnlyClaimableInPublicPhase();
        }

        address caller = msg.sender;
        uint256 amount = 1e18;
        if (airdropToken.balanceOf(address(this)) == 0) {
            revert AirdropV3__ContractHaveNotEnoughBalance();
        }
        if (hasClaimed[caller]) {
            revert AirdropV3__UserHasAlreadyClaim(caller);
        }

        hasClaimed[caller] = true;
        publicPhaseAmount = publicPhaseAmount - 1e18;
        emit ClaimedAirdrop(caller, 1e18);
        airdropToken.safeTransfer(caller, amount);
    }

    /**
     * @notice Getter function for merkle root.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return root;
    }

    /**
     * @notice Getter function for airdrop token.
     */
    function getAirdropToken() external view returns (IERC20) {
        return airdropToken;
    }

    /**
     * @notice Getter function for phase.
     */
    function getPhase() external view returns (PHASE) {
        return phase;
    }

    /**
     * @notice Function for calculating message hash for signature creation.
     */
    function _messageHash(address account, address caller, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, permited: caller, amount: amount})))
        );
    }

    /**
     * @notice Function varifies the signatory of the signature.
     */
    function _verifySignature(address signetory, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        private
        pure
        returns (bool)
    {
        (address signer,,) = ECDSA.tryRecover(digest, v, r, s);
        return (signer == signetory);
    }

    /**
     * @notice Chainlink automation function that ensure whether the upkeep is needed or not. returns true if upkeep needed or else false.
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isPrivate = (phase == PHASE.PRIVATE) ? true : false;
        bool timeDurationPassed = block.timestamp > timeDuration;
        upkeepNeeded = (isPrivate && timeDurationPassed);
    }

    /**
     * @notice Chainlink automation function, performs the upkeep if it is needed.
     */
    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");

        if (!upkeepNeeded) {
            revert AirdropV3__CanNotChangePhase();
        }

        lastTimestamp = block.timestamp;
        interval = 0;
        timeDuration = 0;
        if (privatePhaseAmount > 0) {
            publicPhaseAmount += privatePhaseAmount;
            privatePhaseAmount = 0;
        }
        phase = PHASE.PUBLIC;

        emit AirdropIsNowPublic(lastTimestamp);
    }
}
