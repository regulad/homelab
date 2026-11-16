//! ssh-agent-mux <listen socket> <upstream socket>...
//!
//! One agent socket offering the keys of every upstream agent, in the order
//! given, each signature asked of the agent holding that key.

use std::path::PathBuf;

#[tokio::main(flavor = "current_thread")]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args = std::env::args_os().skip(1).map(PathBuf::from);
    let listen = args
        .next()
        .ok_or("usage: ssh-agent-mux <listen socket> <upstream socket>...")?;
    ssh_agent_mux::MuxAgent::run(listen, args).await?;
    Ok(())
}
