use crate::{
    endpoints::reply::{
        reply_dispatch_callback, reply_init_callback, INIT_CALLBACK_ID, RECEIVE_DISPATCH_ID,
    },
    HostError,
};
use abstract_core::objects::AccountId;
use abstract_sdk::{
    base::{
        AbstractContract, ExecuteHandlerFn, InstantiateHandlerFn, QueryHandlerFn, ReceiveHandlerFn,
        ReplyHandlerFn, SudoHandlerFn,
    },
    core::ibc_host::PacketMsg,
    feature_objects::AnsHost,
    namespaces::{ADMIN_NAMESPACE, BASE_STATE},
    AbstractSdkError,
};
use cosmwasm_std::{Addr, Binary, Empty, StdResult, Storage};
use cw_controllers::Admin;
use cw_storage_plus::{Item, Map};
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// Store channel information for proxy contract creation reply
pub const PENDING: Item<(String, AccountId)> = Item::new("pending");
/// Store the processing packet information for processing in Reply along with the channel id it came from
pub const PROCESSING_PACKET: Item<(PacketMsg, String)> = Item::new("processing");
/// (channel-id,account_id) -> local_proxy_addr
pub const ACCOUNTS: Map<(&str, AccountId), Addr> = Map::new("accounts");
/// (channel-id,account_id) -> client_proxy_addr
pub const CLIENT_PROXY: Map<(&str, AccountId), String> = Map::new("client_proxy");
/// List of closed channels
/// Allows for fund recovery
pub const CLOSED_CHANNELS: Item<Vec<String>> = Item::new("closed");
// this stores all results from current dispatch
pub const RESULTS: Item<Vec<Binary>> = Item::new("results");

pub trait ContractError:
    From<cosmwasm_std::StdError> + From<HostError> + From<AbstractSdkError> + 'static
{
}
impl<T> ContractError for T where
    T: From<cosmwasm_std::StdError> + From<HostError> + From<AbstractSdkError> + 'static
{
}

/// The state variables for our host contract.
pub struct Host<
    Error: ContractError,
    CustomInitMsg: 'static,
    CustomExecMsg: 'static,
    CustomQueryMsg: 'static,
    CustomMigrateMsg: 'static,
    Receive: 'static = Empty,
    SudoMsg: 'static = Empty,
> {
    // Scaffolding contract that handles type safety and provides helper methods
    pub(crate) contract: AbstractContract<Self, Error>,
    pub admin: Admin<'static>,
    // Custom state for every Host
    pub proxy_address: Option<Addr>,
    pub(crate) base_state: Item<'static, HostState>,
    pub(crate) chain: &'static str,
}

// Constructor
impl<
        Error: ContractError,
        CustomInitMsg,
        CustomExecMsg,
        CustomQueryMsg,
        CustomMigrateMsg,
        ReceiveMsg,
        SudoMsg,
    >
    Host<Error, CustomInitMsg, CustomExecMsg, CustomQueryMsg, CustomMigrateMsg, ReceiveMsg, SudoMsg>
{
    pub const fn new(
        name: &'static str,
        version: &'static str,
        chain: &'static str,
        metadata: Option<&'static str>,
    ) -> Self {
        let contract = AbstractContract::new(name, version, metadata).with_replies([
            &[
                // add reply handlers we want to support by default
                (RECEIVE_DISPATCH_ID, reply_dispatch_callback),
                (INIT_CALLBACK_ID, reply_init_callback),
            ],
            &[],
        ]);
        Self {
            contract,
            chain,
            base_state: Item::new(BASE_STATE),
            admin: Admin::new(ADMIN_NAMESPACE),
            proxy_address: None,
        }
    }

    pub fn state(&self, store: &dyn Storage) -> StdResult<HostState> {
        self.base_state.load(store)
    }

    pub fn target(&self) -> Result<&Addr, HostError> {
        self.proxy_address.as_ref().ok_or(HostError::NoTarget)
    }

    pub const fn with_instantiate(
        mut self,
        instantiate_handler: InstantiateHandlerFn<Self, CustomInitMsg, Error>,
    ) -> Self {
        self.contract = self.contract.with_instantiate(instantiate_handler);
        self
    }

    pub const fn with_execute(
        mut self,
        execute_handler: ExecuteHandlerFn<Self, CustomExecMsg, Error>,
    ) -> Self {
        self.contract = self.contract.with_execute(execute_handler);
        self
    }

    pub const fn with_query(
        mut self,
        query_handler: QueryHandlerFn<Self, CustomQueryMsg, Error>,
    ) -> Self {
        self.contract = self.contract.with_query(query_handler);
        self
    }
    /// add reply handler to contract
    pub const fn with_replies(
        mut self,
        reply_handlers: &'static [(u64, ReplyHandlerFn<Self, Error>)],
    ) -> Self {
        // update this to store static iterators
        let mut new_reply_handlers = self.contract.reply_handlers;
        new_reply_handlers[1] = reply_handlers;
        self.contract = self.contract.with_replies(new_reply_handlers);
        self
    }

    pub const fn with_sudo(mut self, sudo_handler: SudoHandlerFn<Self, SudoMsg, Error>) -> Self {
        self.contract = self.contract.with_sudo(sudo_handler);
        self
    }

    pub const fn with_receive(
        mut self,
        receive_handler: ReceiveHandlerFn<Self, ReceiveMsg, Error>,
    ) -> Self {
        self.contract = self.contract.with_receive(receive_handler);
        self
    }
}

/// The BaseState contains the main addresses needed for sending and verifying messages
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct HostState {
    /// AnsHost contract struct (address)
    pub ans_host: AnsHost,
    /// code id for Stargate proxy contract
    pub cw1_code_id: u64,
    /// Chain identifier
    pub chain: String,
}
