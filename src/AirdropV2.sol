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

    constructor(string memory name, string memory version) Ownable(msg.sender) EIP712(name, version) {}

    function setAirdrop(bytes32 _root, IERC20 token) external onlyOwner {
        root = _root;
        airdropToken = token;
    }

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

    function getMerkleRoot() external view returns (bytes32) {
        return root;
    }

    function getAirdropToken() external view returns (IERC20) {
        return airdropToken;
    }

    function _messageHash(address account, address caller, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, permited: caller, amount: amount})))
        );
    }

    function _verifySignature(address signetory, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        private
        pure
        returns (bool)
    {
        (address signer,,) = ECDSA.tryRecover(digest, v, r, s);
        return (signer == signetory);
    }
}
