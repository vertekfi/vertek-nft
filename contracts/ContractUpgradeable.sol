

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract ContractUpgradeable  is AccessControlUpgradeable {

    bytes32 public constant MY_ROLE = keccak256("MY_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        /**
         * Prevents later initialization attempts after deployment.
         * If a base contract was left uninitialized, the implementation contracts
         * could potentially be compromised in some way.
         */
        _disableInitializers();
    }


    function initialize() public initializer {
      // Call all base initializers
      __AccessControl_init();
    }
}