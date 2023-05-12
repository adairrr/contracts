use abstract_core::objects::gov_type::GovernanceDetails;
use abstract_interface::Abstract;

use clap::Parser;
use cw_orch::networks::juno::JUNO_NETWORK;
use cw_orch::networks::{ChainInfo, ChainKind};
use cw_orch::{
    networks::{parse_network, NetworkInfo},
    *,
};
use semver::Version;
use std::sync::Arc;
use tokio::runtime::Runtime;

pub const ABSTRACT_VERSION: &str = env!("CARGO_PKG_VERSION");

pub const JUNO_1: ChainInfo = ChainInfo {
    kind: ChainKind::Mainnet,
    chain_id: "juno-1",
    gas_denom: "ujuno",
    gas_price: 0.0025,
    grpc_urls: &["http://juno-grpc.polkachu.com:12690"],
    chain_info: JUNO_NETWORK,
    lcd_url: None,
    fcd_url: None,
};

fn full_deploy(_network: ChainInfo) -> anyhow::Result<()> {
    let abstract_version: Version = ABSTRACT_VERSION.parse().unwrap();

    let rt = Arc::new(Runtime::new()?);
    let chain = DaemonBuilder::default()
        .handle(rt.handle())
        .chain(JUNO_1)
        .build()?;
    let sender = chain.sender();
    let deployment = Abstract::deploy_on(chain, abstract_version)?;

    // CReate the Abstract Account because it's needed for the fees for the dex module
    deployment
        .account_factory
        .create_default_account(GovernanceDetails::Monarchy {
            monarch: sender.to_string(),
        })?;

    // let _dex = DexAdapter::new("dex", chain);

    // deployment.deploy_modules()?;

    let ans_host = deployment.ans_host;
    ans_host.update_all()?;

    Ok(())
}

#[derive(Parser, Default, Debug)]
#[command(author, version, about, long_about = None)]
struct Arguments {
    /// Network Id to deploy on
    #[arg(short, long)]
    network_id: String,
}

fn main() {
    dotenv().ok();
    env_logger::init();

    use dotenv::dotenv;

    let args = Arguments::parse();

    let network = parse_network(&args.network_id);

    if let Err(ref err) = full_deploy(network) {
        log::error!("{}", err);
        err.chain()
            .skip(1)
            .for_each(|cause| log::error!("because: {}", cause));

        // The backtrace is not always generated. Try to run this example
        // with `$env:RUST_BACKTRACE=1`.
        //    if let Some(backtrace) = e.backtrace() {
        //        log::debug!("backtrace: {:?}", backtrace);
        //    }

        ::std::process::exit(1);
    }
}
