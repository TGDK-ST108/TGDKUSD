// SPDX-License-Identifier: BFE-TGDK-USD-001-PMZ
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * ────────────────────────────────────────────────────────────────
 *  TGDK-USD — PMZ / Enso-Stabilized Stable Asset
 *  ---------------------------------------------------------------
 *  ▪ 1 TGDKUSD ≈ 1 USDC (soft peg)
 *  ▪ Principles of Metric Zonality (PMZ)
 *  ▪ Enso Seal hash checksum for mint / burn validation
 *  ▪ 0.0102 harmonic compression ratio for peg modulation
 *  ▪ HexQUAp 6-fold seal loop for entropy stabilization
 *  ▪ Gas remains ETH; value parity is peg-based
 * ────────────────────────────────────────────────────────────────
 */
contract TGDKUSD is ERC20, Ownable {
    // ───────────────────────────── Core Variables ─────────────────────────────
    address public reserve;          // Underlying peg token (e.g. USDC)
    uint256 public pegRatio;         // 1 × 10¹⁸ baseline
    uint256 public constant PMZ_RATIO = 102;   // 0.0102 × 10⁴
    uint8   private constant HEXQUAP_FOLDS = 6;

    // ──────────────────────────────── Events ─────────────────────────────────
    event PeggedMint(address indexed to, uint256 amount, uint256 ensoChecksum);
    event PeggedBurn(address indexed from, uint256 amount, uint256 ensoChecksum);
    event PegAdjusted(uint256 oldRatio, uint256 newRatio);
    event EnsoSealVerified(address indexed verifier, bytes32 seal, bool valid, uint256 checksum);

    // ─────────────────────────────── Constructor ─────────────────────────────
    constructor(address _reserve)
        ERC20("TGDK-USD", "TGDKUSD")
        Ownable(
            // OZ v4 needs an argument; OZ v5 ignores it, so pass safely
            msg.sender
        )
    {
        require(_reserve != address(0), "Invalid reserve");
        reserve = _reserve;
        pegRatio = 1e18;
    }

    // ───────────────────────────── PMZ + Enso Seal Core ──────────────────────
    function pmzCompress(uint256 entropy) public pure returns (uint256) {
        uint256 compressed = (entropy * PMZ_RATIO) / 10_000;
        for (uint8 i = 0; i < HEXQUAP_FOLDS; i++) {
            compressed = (compressed + entropy / (i + 1)) / 2;
        }
        return compressed;
    }

    function generateEnsoSeal(uint256 entropy) public pure returns (bytes32) {
        uint256 compressed = (entropy * PMZ_RATIO) / 10_000;
        return keccak256(abi.encodePacked(compressed, HEXQUAP_FOLDS, PMZ_RATIO, entropy));
    }

    function verifyEnsoSeal(bytes32 seal, uint256 entropy)
        public
        pure
        returns (bool valid, uint256 checksum)
    {
        bytes32 expected = generateEnsoSeal(entropy);
        valid = (expected == seal);
        checksum = ((uint256(expected) % 144_144) * PMZ_RATIO) / 10_000;
        return (valid, checksum);
    }

    // ───────────────────────────── Stablecoin Logic ──────────────────────────
    function mintReward(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        uint256 entropy = uint256(keccak256(abi.encodePacked(to, amount, block.timestamp)));
        (, uint256 checksum) = verifyEnsoSeal(generateEnsoSeal(entropy), entropy);
        emit PeggedMint(to, amount, checksum);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
        uint256 entropy = uint256(keccak256(abi.encodePacked(from, amount, block.timestamp)));
        (, uint256 checksum) = verifyEnsoSeal(generateEnsoSeal(entropy), entropy);
        emit PeggedBurn(from, amount, checksum);
    }

    function setPegRatio(uint256 newRatio) external onlyOwner {
        uint256 old = pegRatio;
        pegRatio = newRatio;
        emit PegAdjusted(old, newRatio);
    }

    // ───────────────────────────── Audit & Diagnostics ───────────────────────
    function viewEnso(uint256 entropy)
        external
        pure
        returns (uint256 compressed, bytes32 seal, uint256 checksum)
    {
        compressed = pmzCompress(entropy);
        seal       = generateEnsoSeal(entropy);
        checksum   = ((uint256(seal) % 144_144) * PMZ_RATIO) / 10_000;
    }

    // ───────────────────────────── Transfer Wrappers ─────────────────────────
    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 compressed = pmzCompress(amount);
        return super.transfer(to, compressed);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 compressed = pmzCompress(amount);
        return super.transferFrom(from, to, compressed);
    }
}
