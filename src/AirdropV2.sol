// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Proton} from "./token/proton.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract AirdropV2 is Ownable, EIP712 {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    error AirdropV2__InvalidProof();
    error AirdropV2__UserHasAlreadyClaim(address account);
    error AirdropV2__InvalidSignature();
    error AirdropV2__InvalidArrayLength();

    IERC20 private airdropToken;
    bytes32 private root;
    bytes32 private constant MESSAGE_TYPEHASH =
        keccak256("AirdropClaim(address account,address permitted,uint256 amount)");

    uint256 nonce = 0;

    mapping(address => bool) public hasClaimed;

    struct AirdropClaim {
        address account;
        address permited;
        uint256 amount;
    }

    event ClaimedAirdrop(address account, uint256 amount);
    event ClaimSkiped(address account, string message);

    constructor(string memory name, string memory version) Ownable(msg.sender) EIP712(name, version) {}

    /**
     * The admin function which allows the owner to setup the airdrop for the intended token.
     * @param _root Merkle root for the airdrop, To varify the claimer.
     * @param token Token for which the airdrop will be set.
     */
    function setAirdrop(bytes32 _root, IERC20 token) external onlyOwner {
        root = _root;
        airdropToken = token;
    }

    /**
     * @dev Proof will ensure that only intended user or whitelisted user can claim their amount of tokens.
     * @param amount Amount the user wants to claim.
     * @param proof Array of proof that verify the claimer and the amount.
     */
    function claimAirdrop(uint256 amount, bytes32[] calldata proof) external {
        address account = msg.sender;
        if (hasClaimed[account]) {
            revert AirdropV2__UserHasAlreadyClaim(account);
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(proof, root, leaf)) {
            revert AirdropV2__InvalidProof();
        }

        hasClaimed[account] = true;
        emit ClaimedAirdrop(account, amount);
        airdropToken.safeTransfer(account, amount);
    }

    /**
     * @notice Any user who is permited to claim tokens on behalf of the whitelistd claimer can call this fucntion, but they should have signature signed by the claimer.
     * @param account The account for the user wants to claim.
     * @param amount Amount for the account the user want to claim.
     * @param proof Proof to verify the whitelisted claimer and amount.
     * @dev v, r, s The component oof signature user has signed.
     */
    function claimPermeet(address account, uint256 amount, bytes32[] calldata proof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        address caller = msg.sender;

        if (hasClaimed[account]) {
            revert AirdropV2__UserHasAlreadyClaim(account);
        }

        if (!_verifySignature(account, _messageHash(account, caller, amount), v, r, s)) {
            revert AirdropV2__InvalidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(proof, root, leaf)) {
            revert AirdropV2__InvalidProof();
        }

        hasClaimed[account] = true;
        emit ClaimedAirdrop(account, amount);
        airdropToken.safeTransfer(account, amount);
    }

    /**
     * @dev function allows any user to batch claim for whitelisted claimers.
     * @param accounts Array of accounts for user wants to claim.
     * @param amounts Array of amount corresponding to the account.
     * @param proofs Array of proofs corresponding to the account.
     */
    function batchClaim(address[] memory accounts, uint256[] memory amounts, bytes32[][] memory proofs) external {
        if (accounts.length != amounts.length || accounts.length != proofs.length) {
            revert AirdropV2__InvalidArrayLength();
        }
        uint256 i = 0;
        for (; i < accounts.length; ++i) {
            if (hasClaimed[accounts[i]]) {
                emit ClaimSkiped(accounts[i], "Account has already claimed");
                continue;
            }
            bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(accounts[i], amounts[i]))));
            if (!MerkleProof.verify(proofs[i], root, leaf)) {
                emit ClaimSkiped(accounts[i], "Invalid proof");
                continue;
            }

            hasClaimed[accounts[i]] = true;

            emit ClaimedAirdrop(accounts[i], amounts[i]);

            airdropToken.safeTransfer(accounts[i], amounts[i]);
        }
    }

    /**
     * @dev Getter function of merkle root.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return root;
    }

    /**
     * @dev Getter function of airdrop token.
     */
    function getAirdropToken() external view returns (IERC20) {
        return airdropToken;
    }

    /**
     * @dev Getter function to get message hash for generating signature.
     */
    function _messageHash(address account, address caller, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, permited: caller, amount: amount})))
        );
    }

    /**
     * @dev Function to verify the signatory of the signature.
     */
    function _verifySignature(address signetory, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        private
        pure
        returns (bool)
    {
        (address signer,,) = ECDSA.tryRecover(digest, v, r, s);
        return (signer == signetory);
    }
}
