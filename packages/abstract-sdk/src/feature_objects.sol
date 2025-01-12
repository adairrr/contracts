//! # Structs that implement a feature trait
//!
//! Feature objects are objects that store sufficient data to unlock some functionality.
//! These objects are mostly used internally to easy re-use application code without
//! requiring the usage of a base contract.

use crate::{
    features::{AbstractRegistryAccess, AccountIdentification, ModuleIdentification},
    AbstractSdkResult,
};
pub use abstract_core::objects::ans_host::AnsHost;
use abstract_core::version_control::AccountBase;
use core::PROXY;
use cosmwasm_std::{Addr, Deps};

/// Store the Version Control contract.
/// Implements [`AbstractRegistryAccess`]
#[derive(Clone)]
pub struct VersionControlContract {
    pub address: Addr,
}

impl VersionControlContract {
    pub fn new(address: Addr) -> Self {
        Self { address }
    }
}

impl AbstractRegistryAccess for VersionControlContract {
    fn abstract_registry(&self, _deps: Deps) -> AbstractSdkResult<Addr> {
        Ok(self.address.clone())
    }
}

/// Store a proxy contract address.
/// Implements [`AccountIdentification`].
#[derive(Clone)]
pub struct ProxyContract {
    pub contract_address: Addr,
}

impl ProxyContract {
    pub fn new(address: Addr) -> Self {
        Self {
            contract_address: address,
        }
    }
}

impl AccountIdentification for ProxyContract {
    fn proxy_address(&self, _deps: Deps) -> AbstractSdkResult<Addr> {
        Ok(self.contract_address.clone())
    }
}

impl ModuleIdentification for ProxyContract {
    fn module_id(&self) -> &'static str {
        PROXY
    }
}

impl AccountIdentification for AccountBase {
    fn proxy_address(&self, _deps: Deps) -> AbstractSdkResult<Addr> {
        Ok(self.proxy.clone())
    }

    fn manager_address(&self, _deps: Deps) -> AbstractSdkResult<Addr> {
        Ok(self.manager.clone())
    }

    fn account_base(&self, _deps: Deps) -> AbstractSdkResult<AccountBase> {
        Ok(self.clone())
    }
}

impl ModuleIdentification for AccountBase {
    /// Any actions executed by the core will be by the proxy address
    fn module_id(&self) -> &'static str {
        PROXY
    }
}

impl crate::features::AbstractNameService for AnsHost {
    fn ans_host(
        &self,
        _deps: Deps,
    ) -> AbstractSdkResult<abstract_core::objects::ans_host::AnsHost> {
        Ok(self.clone())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use abstract_testing::prelude::{TEST_MANAGER, TEST_PROXY};
    use speculoos::prelude::*;

    mod version_control {
        use super::*;
        use cosmwasm_std::testing::mock_dependencies;

        #[test]
        fn test_registry() {
            let address = Addr::unchecked("version");
            let vc = VersionControlContract::new(address.clone());

            let deps = mock_dependencies();

            assert_that!(vc.abstract_registry(deps.as_ref()))
                .is_ok()
                .is_equal_to(address);
        }
    }

    mod proxy {
        use super::*;
        use cosmwasm_std::testing::mock_dependencies;

        #[test]
        fn test_proxy_address() {
            let address = Addr::unchecked(TEST_PROXY);
            let proxy = ProxyContract::new(address.clone());
            let deps = mock_dependencies();

            assert_that!(proxy.proxy_address(deps.as_ref()))
                .is_ok()
                .is_equal_to(address);
        }

        #[test]
        fn should_identify_self_as_abstract_proxy() {
            let proxy = ProxyContract::new(Addr::unchecked(TEST_PROXY));

            assert_that!(proxy.module_id()).is_equal_to(PROXY);
        }
    }

    mod base {
        use super::*;
        use cosmwasm_std::testing::mock_dependencies;

        fn test_account_base() -> AccountBase {
            AccountBase {
                manager: Addr::unchecked(TEST_MANAGER),
                proxy: Addr::unchecked(TEST_PROXY),
            }
        }

        #[test]
        fn test_proxy_address() {
            let address = Addr::unchecked(TEST_PROXY);
            let account_base = test_account_base();

            let deps = mock_dependencies();

            assert_that!(account_base.proxy_address(deps.as_ref()))
                .is_ok()
                .is_equal_to(address);
        }

        #[test]
        fn test_manager_address() {
            let manager_addrsess = Addr::unchecked(TEST_MANAGER);
            let account_base = test_account_base();

            let deps = mock_dependencies();

            assert_that!(account_base.manager_address(deps.as_ref()))
                .is_ok()
                .is_equal_to(manager_addrsess);
        }

        #[test]
        fn test_account() {
            let account_base = test_account_base();

            let deps = mock_dependencies();

            assert_that!(account_base.account_base(deps.as_ref()))
                .is_ok()
                .is_equal_to(account_base);
        }

        #[test]
        fn should_identify_self_as_abstract_proxy() {
            let account_base = test_account_base();

            assert_that!(account_base.module_id()).is_equal_to(PROXY);
        }
    }
}
