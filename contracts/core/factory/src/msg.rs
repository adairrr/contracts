use dao_os::governance::gov_type::GovernanceDetails;
use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct InstantiateMsg {
    /// Version control contract used to get code-ids and register OS
    pub version_control_contract: String,
    /// Memory contract
    pub memory_contract: String,
    // Creation fee in some denom (TBD)
    pub creation_fee: u32,
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum ExecuteMsg {
    /// Update config
    UpdateConfig {
        admin: Option<String>,
        memory_contract: Option<String>,
        version_control_contract: Option<String>,
        creation_fee: Option<u32>,
    },
    /// Creates the core contracts for the OS
    CreateOs {
        /// Governance details
        /// TODO: add support for other types of gov.
        governance: GovernanceDetails,
    },
}

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
#[serde(rename_all = "snake_case")]
pub enum QueryMsg {
    Config {},
}

// We define a custom struct for each query response
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct ConfigResponse {
    pub owner: String,
    pub memory_contract: String,
    pub version_control_contract: String,
    pub creation_fee: u32,
    pub os_id_sequence: u32,
}

/// We currently take no arguments for migrations
#[derive(Serialize, Deserialize, Clone, Debug, PartialEq, JsonSchema)]
pub struct MigrateMsg {}
