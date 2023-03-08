// SPDX-License-Identifier: MIT

/***
 *   ___      ___  _______   _______  ___________  _______  __   ___      _____  ___    _______  ___________  ________
 *|"  \    /"  |/"     "| /"      \("     _   ")/"     "||/"| /  ")    (\"   \|"  \  /"     "|("     _   ")/"       )
 * \   \  //  /(: ______)|:        |)__/  \\__/(: ______)(: |/   /     |.\\   \    |(: ______) )__/  \\__/(:   \___/
 *  \\  \/. ./  \/    |  |_____/   )   \\_ /    \/    |  |    __/      |: \.   \\  | \/    |      \\_ /    \___  \
 *   \.    //   // ___)_  //      /    |.  |    // ___)_ (// _  \      |.  \    \. | // ___)      |.  |     __/  \\
 *    \\   /   (:      "||:  __   \    \:  |   (:      "||: | \  \     |    \    \ |(:  (         \:  |    /" \   :)
 *     \__/     \_______)|__|  \___)    \__|    \_______)(__|  \__)     \___|\____\) \__/          \__|   (_______/
 *
 * Vertek Landing Page: https://www.vertek.org/
 * Vertek Dapp: https://www.vertek.exchange/
 * Discord: https://discord.gg/vertek-ames-aalto
 * Medium: https://medium.com/@verteklabs
 * Twitter: https://twitter.com/Vertek_Dex
 * Telegram: https://t.me/aalto_protocol
 */

pragma solidity 0.8.13;

import "./ERC721AQueryable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract VertekFox is ERC721AQueryable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using StringsUpgradeable for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 public merkleRoot;
    mapping(address => bool) public whitelistClaimed;
    mapping(uint256 => uint256) public baseRarity;
    address public rarityUpdaterAddress;

    uint256 internal _seedRarity;
    uint256 internal rarityAssigned;
    uint256 internal internalIndex;

    mapping(uint256 => uint256) public attackRarity;
    mapping(uint256 => uint256) public defenseRarity;
    uint256 internal a_seedRarity;
    uint256 internal d_seedRarity;

    string public uriPrefix;
    string public uriSuffix;
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmountPerTx;

    bool public paused;
    bool public whitelistMintEnabled;
    bool public revealed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        /**
         * Prevents later initialization attempts after deployment.
         * If a base contract was left uninitialized, the implementation contracts
         * could potentially be compromised in some way.
         */
        _disableInitializers();
    }

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) public initializer {
        __ERC721A_init(_tokenName, _tokenSymbol);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);

        setCost(_cost);
        maxSupply = _maxSupply;
        setMaxMintAmountPerTx(_maxMintAmountPerTx);
        setHiddenMetadataUri(_hiddenMetadataUri);
        rarityUpdaterAddress = msg.sender;

        uriPrefix = "";
        uriSuffix = ".json";

        a_seedRarity = 3;
        d_seedRarity = 7;

        _seedRarity = 1;
        internalIndex = 1;

        paused = true;
        whitelistMintEnabled = false;
        revealed = false;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliance(uint256 _mintAmount) {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _;
    }

    modifier assignRarity(uint256 _mintAmount) {
        uint256 raritySeed = block.timestamp;
        for (uint i = 0; i < _mintAmount; i++) {
            uint256 rarityModulus = ((raritySeed % 10) + _seedRarity) % 10;
            if (rarityModulus == 0) {
                rarityAssigned = 4;
            }
            if (rarityModulus >= 1 && rarityModulus <= 2) {
                rarityAssigned = 3;
            }
            if (rarityModulus >= 3 && rarityModulus <= 5) {
                rarityAssigned = 2;
            }
            if (rarityModulus >= 6 && rarityModulus <= 10) {
                rarityAssigned = 1;
            }
            baseRarity[internalIndex] = rarityAssigned;
            rarityModulus++;
            _seedRarity = rarityModulus;
            attackRarity[internalIndex] = (((raritySeed % 35) + a_seedRarity) % 40) - 4;
            defenseRarity[internalIndex] = ((raritySeed % 30) + d_seedRarity + _seedRarity) % 40;
            a_seedRarity = a_seedRarity + d_seedRarity;
            d_seedRarity = d_seedRarity + _seedRarity;
            internalIndex++;
        }
        _;
    }

    modifier onlyRarityUpdaterAddress() {
        require(rarityUpdaterAddress == msg.sender, "caller is not the operator");
        _;
    }

    modifier onlyOperator() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(OPERATOR_ROLE, _msgSender()), "Only operator");
        _;
    }

    function setRarityUpdaterAddress(address _rarityUpdaterAddress) external onlyOperator {
        rarityUpdaterAddress = _rarityUpdaterAddress;
    }

    function setAttack(uint256 _tokenId, uint256 _attack) external onlyRarityUpdaterAddress {
        attackRarity[_tokenId] = _attack;
    }

    function setDefenseRarity(uint256 _tokenId, uint256 _defense) external onlyRarityUpdaterAddress {
        defenseRarity[_tokenId] = _defense;
    }

    function whitelistMint(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) assignRarity(_mintAmount) {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(!whitelistClaimed[_msgSender()], "Address already claimed!");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");

        whitelistClaimed[_msgSender()] = true;
        _safeMint(_msgSender(), _mintAmount);
    }

    function mint(
        uint256 _mintAmount
    ) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) assignRarity(_mintAmount) {
        require(!paused, "The contract is paused!");
        _safeMint(_msgSender(), _mintAmount);
    }

    function mintForAddress(
        uint256 _mintAmount,
        address _receiver
    ) public mintCompliance(_mintAmount) onlyOperator assignRarity(_mintAmount) {
        _safeMint(_receiver, _mintAmount);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override(ERC721A, IERC721MetadataUpgradeable) returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
                : "";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlUpgradeable, ERC721A, IERC165Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRevealed(bool _state) public onlyOperator {
        revealed = _state;
    }

    function setCost(uint256 _cost) public onlyOperator {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOperator {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOperator {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOperator {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOperator {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOperator {
        paused = _state;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOperator {
        merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOperator {
        whitelistMintEnabled = _state;
    }

    function withdraw(address recipient) public onlyOperator nonReentrant {
        require(recipient != address(0), "Cannot withdraw to zero address");
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(recipient).call{ value: address(this).balance }("");
        require(os, "Withdraw call failed");
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
