import { ethers } from "ethers";
import {
  CONTRACT_ABI,
  CONTRACT_ADDRESS,
  //   LOCAL_ANVIL_ADDRESS,
} from "../assets/contractABI.js";
import {
  createContext,
  ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { useWeb3 } from "./Web3ContextProvider.js";

const RaffleContext = createContext<null | {
  isRaffleOpen: boolean;
  entrance: string;
  handleEnterRaffle: () => void;
  rafflePrize: string;
  lastRaffleDate: string;
  lastWinner: string;
}>(null);

export default function RaffleContextProvider({
  children,
}: Readonly<{ children: ReactNode }>) {
  const { provider, signer } = useWeb3();
  //   const [isSuccessfulEntrance, setSuccessfulEntrance] = useState(false);
  const [lastWinner, setLastWinner] = useState("");
  const [lastRaffleDate, setRaffleDate] = useState("");
  const [isRaffleOpen, setOpen] = useState(false);
  const [entrance, setEntrance] = useState("");
  const [rafflePrize, setRafflePrize] = useState("");

  const contract = useMemo(() => {
    return new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  }, [signer]);

  //TODODODODD - Think about loading state using use and suspense
  useEffect(() => {
    const handleGetEntranceFee = async () => {
      const rafflePrize = await provider.getBalance(CONTRACT_ADDRESS);

      const entranceWei = await contract.getEntranceFee();
      const raffleState = await contract.getRaffleState();
      const lastWinnerAddress = await contract.getRecentWinner();
      const lastTimeStamp = await contract.getLastTimeStamp();
      const date = new Date(Number(lastTimeStamp) * 1000);
      const formattedDate = date.toLocaleString();

      const ether = ethers.formatEther(entranceWei);
      const prizeEther = ethers.formatEther(rafflePrize);

      setLastWinner(lastWinnerAddress);
      setRaffleDate(formattedDate);
      setRafflePrize(prizeEther);
      setOpen(raffleState);
      setEntrance(ether);
    };

    handleGetEntranceFee();
  }, [contract, provider]);

  const handleEnterRaffle = async () => {
    const entranceFee = await contract.getEntranceFee();
    await contract.enterRaffle({
      value: entranceFee,
    });
  };
  const store = {
    isRaffleOpen,
    entrance,
    handleEnterRaffle,
    rafflePrize,
    lastRaffleDate,
    lastWinner,
  };

  return (
    <RaffleContext.Provider value={store}>{children}</RaffleContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export const useRaffle = () => {
  const context = useContext(RaffleContext);
  if (!context) {
    throw new Error("Invalid context");
  }
  return context;
};
