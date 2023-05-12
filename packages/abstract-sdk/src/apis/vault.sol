//! # Vault
//! The Vault object provides function for querying balances and asset values for the Account.

use crate::{
    cw_helpers::cosmwasm_std::wasm_smart_query,
    features::{AbstractNameService, AccountIdentification},
    AbstractSdkResult,
};
use abstract_core::{objects::AssetEntry, proxy::QueryMsg};
use cosmwasm_std::{Deps, Uint128};

use abstract_core::{
    objects::oracle::{self, AccountValue},
    proxy::{AssetsInfoResponse, BaseAssetResponse, TokenValueResponse},
};

/// Retrieve asset-registration information from the Account.
/// Query asset values and balances.
pub trait VaultInterface: AbstractNameService + AccountIdentification {
    fn vault<'a>(&'a self, deps: Deps<'a>) -> Vault<Self> {
        Vault { base: self, deps }
    }
}

impl<T> VaultInterface for T where T: AbstractNameService + AccountIdentification {}

#[derive(Clone)]
pub struct Vault<'a, T: VaultInterface> {
    base: &'a T,
    deps: Deps<'a>,
}

impl<'a, T: VaultInterface> Vault<'a, T> {
    /// Query the total value denominated in the base asset
    /// The provided address must implement the TotalValue Query
    pub fn query_total_value(&self) -> AbstractSdkResult<AccountValue> {
        let querier = self.deps.querier;
        let proxy_address = self.base.proxy_address(self.deps)?;
        let response: AccountValue = querier.query(&wasm_smart_query(
            proxy_address.to_string(),
            &QueryMsg::TotalValue {},
        )?)?;

        Ok(response)
    }

    /// Query the asset value denominated in the base asset
    pub fn asset_value(&self, asset_entry: AssetEntry) -> AbstractSdkResult<Uint128> {
        let querier = self.deps.querier;
        let proxy_address = self.base.proxy_address(self.deps)?;
        let response: TokenValueResponse = querier.query(&wasm_smart_query(
            proxy_address.to_string(),
            &QueryMsg::TokenValue {
                identifier: asset_entry,
            },
        )?)?;

        Ok(response.value)
    }

    /// Return the proxy's base asset
    pub fn base_asset(&self) -> AbstractSdkResult<BaseAssetResponse> {
        let querier = self.deps.querier;
        let proxy_address = self.base.proxy_address(self.deps)?;
        let response: BaseAssetResponse = querier.query(&wasm_smart_query(
            proxy_address.to_string(),
            &QueryMsg::BaseAsset {},
        )?)?;

        Ok(response)
    }

    /// List enabled assets (AssetInfos)
    pub fn assets_list(&self) -> AbstractSdkResult<AssetsInfoResponse> {
        let querier = self.deps.querier;
        let proxy_address = self.base.proxy_address(self.deps)?;

        let resp: AssetsInfoResponse = querier.query_wasm_smart(
            proxy_address,
            &QueryMsg::AssetsInfo {
                start_after: None,
                limit: Some(oracle::LIST_SIZE_LIMIT),
            },
        )?;

        Ok(resp)
    }

    // /// List ProxyAssets raw
    // pub fn proxy_assets_list(&self) -> AbstractSdkResult<Vec<(AssetEntry, ProxyAsset)>> {
    //     let querier = self.deps.querier;
    //     let proxy_address = self.base.proxy_address(self.deps)?;

    //     let mut assets = vec![];
    //     let mut resp: AssetsResponse = querier.query_wasm_smart(
    //         &proxy_address,
    //         &QueryMsg::Assets {
    //             start_after: None,
    //             limit: None,
    //         },
    //     )?;
    //     while !resp.assets.is_empty() {
    //         let start_after = resp.assets.last().unwrap().0.clone();
    //         assets.append(resp.assets.as_mut());
    //         resp = querier.query_wasm_smart(
    //             &proxy_address,
    //             &QueryMsg::Assets {
    //                 start_after: Some(start_after.to_string()),
    //                 limit: None,
    //             },
    //         )?;
    //     }
    //     Ok(assets)
    // }
}

#[cfg(test)]
mod test {
    // use super::*;
    // use crate::mock_module::*;

    mod query_total_value {
        // use super::*;
    }
}
