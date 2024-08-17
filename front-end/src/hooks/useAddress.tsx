import { useCallback, useEffect, useState } from "react";
import { useWeb3 } from "../providers/Web3ContextProvider";
import { ethers } from "ethers";

export default function useAddress() {
  const { provider } = useWeb3();
  const [balance, setBalance] = useState("");
  const [currentAddress, setCurrentAddress] = useState<string | null>(null);

  window.ethereum.on("accountsChanged", async (accounts: string[]) => {
    const address = accounts[0];
    const balanceWei = await provider.getBalance(address);
    const etherBalance = ethers.formatEther(balanceWei);
    setCurrentAddress(address);
    setBalance(etherBalance);
  });

  useEffect(() => {
    const fetchAddressData = async () => {
      const signer = await provider.getSigner();

      const address = await signer.getAddress();
      const balanceWei = await provider.getBalance(address);
      const etherBalance = ethers.formatEther(balanceWei);
      setCurrentAddress(address);
      setBalance(etherBalance);
    };
    fetchAddressData();
  }, [provider]);

  const handleConnectToWallet = useCallback(async () => {
    await provider.send("eth_requestAccounts", []);
    const signer = await provider.getSigner();
    const address = await signer.getAddress();
    setCurrentAddress(address);
  }, [provider]);

  return {
    currentAddress,
    balance,
    handleConnectToWallet,
  };
}
