import { Signer } from "ethers";
import { ethers } from "ethers";
import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useState,
} from "react";

type Provider = ethers.BrowserProvider;

const Web3Context = createContext<null | {
  provider: Provider;
  signer: Signer;
}>(null);

const provider = new ethers.BrowserProvider(window.ethereum);

export default function Web3ContextProvider({
  children,
}: Readonly<{ children: ReactNode }>) {
  const [signer, setSigner] = useState<Signer | null>(null);

  useEffect(() => {
    (async () => {
      const signer = await provider.getSigner();
      setSigner(signer);
    })();
  }, []);

  if (!signer) {
    return null;
  }

  return (
    <Web3Context.Provider value={{ provider, signer }}>
      {children}
    </Web3Context.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export const useWeb3 = () => {
  const context = useContext(Web3Context);
  if (!context) {
    throw new Error("Invalid context");
  }
  return context;
};
