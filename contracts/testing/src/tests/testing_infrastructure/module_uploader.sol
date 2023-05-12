use abstract_sdk::core::{
    objects::{module::ModuleInfo, module_reference::ModuleReference},
    version_control as VCMsg,
};
use anyhow::Result as AnyResult;
use cosmwasm_std::{Addr, Empty};
use cw_multi_test::{App, Contract, Executor};

pub fn register_app(
    app: &mut App,
    sender: &Addr,
    version_control: &Addr,
    module: ModuleInfo,
    contract: Box<dyn Contract<Empty>>,
) -> AnyResult<()> {
    let code_id = app.store_code(contract);
    let msg = VCMsg::ExecuteMsg::ProposeModules {
        modules: vec![(module, ModuleReference::App(code_id))],
    };
    app.execute_contract(sender.clone(), version_control.clone(), &msg, &[])?;
    Ok(())
}

pub fn register_api(
    app: &mut App,
    sender: &Addr,
    version_control: &Addr,
    module: ModuleInfo,
    address: Addr,
) -> AnyResult<()> {
    let msg = VCMsg::ExecuteMsg::ProposeModules {
        modules: vec![(module, ModuleReference::Api(address))],
    };
    app.execute_contract(sender.clone(), version_control.clone(), &msg, &[])?;
    Ok(())
}
