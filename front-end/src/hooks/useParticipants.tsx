import { useCallback, useState } from "react";
import { useWeb3 } from "../providers/Web3ContextProvider";

const _addresses = ["0x1234...abcd", "0x5678...efgh", "0x9abc...ijkl"];

export default function useParticipants() {
  const { provider } = useWeb3();
  const [addresses, setAddresses] = useState<string[]>(_addresses);

  const addNewAddress = useCallback(async () => {
    const signer = await provider.getSigner();
    const address = await signer.getAddress();

    setAddresses((prev) => {
      return [address, ...prev];
    });
  }, [provider]);

  return {
    addresses,
    addNewAddress,
  };
}
