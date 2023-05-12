use abstract_sdk::core::manager as manager_msg;
use abstract_sdk::core::modules::Module;
use abstract_sdk::core::version_control::Core;
use anyhow::Result as AnyResult;
use cosmwasm_std::{to_binary, Addr};
use cw_multi_test::{App, Executor};
use serde::Serialize;

pub trait BaseActions {
    fn add_module<T: Serialize>(
        &self,
        app: &mut App,
        sender: &Addr,
        module: Module,
        initmsg: Option<T>,
    ) -> AnyResult<()>;
}

impl BaseActions for Core {
    fn add_module<T: Serialize>(
        &self,
        app: &mut App,
        sender: &Addr,
        module: Module,
        init_msg: Option<T>,
    ) -> AnyResult<()> {
        let msg = manager_msg::ExecuteMsg::InstallModule {
            module,
            init_msg: init_msg.map(|msg| to_binary(&msg).unwrap()),
        };
        app.execute_contract(sender.clone(), self.manager.clone(), &msg, &[])?;
        Ok(())
    }
}
