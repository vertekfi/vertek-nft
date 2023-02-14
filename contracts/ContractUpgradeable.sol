
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract ContractUpgradeable  is AccessControlUpgradeable {

     bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

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

      _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _grantRole(ADMIN_ROLE, _msgSender());
    }
}