
module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
    const chainId = await getChainId();

    const staker = await ethers.getContract("Staker", deployer);

    const externalContract = await ethers.getContract("ExternalContract", deployer);

    await externalContract.setOwner(staker.address);

};

module.exports.tags = ["SetOwner"];