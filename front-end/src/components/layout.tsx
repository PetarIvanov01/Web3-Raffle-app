import { ethers } from "ethers";

import useAddress from "../hooks/useAddress";

import ListOfParticipants from "./listOfParticipants";
import Controllers from "./controllers";
import useParticipants from "../hooks/useParticipants";
import RaffleContextProvider, {
  useRaffle,
} from "../providers/RaffleContextProvider";

// const customHttpProvider = new ethers.JsonRpcProvider(
//   "https://eth-sepolia.g.alchemy.com/v2/5qiMRNOOqfMyieeTkHDvuut7z_JEEhOt"
// );
const getEtherScanUrl = (address: string) => {
  return `https://sepolia.etherscan.io/address/${address}`;
};

export default function Layout() {
  const { currentAddress, balance } = useAddress();
  const { addresses, addNewAddress } = useParticipants();

  const { isRaffleOpen, rafflePrize, lastRaffleDate, lastWinner } = useRaffle();

  return (
    <>
      {/* Display Current Address */}
      <section className="mb-3 text-center">
        {currentAddress ? (
          <div className="text-gray-700">
            <p>
              <span className="text-[1.3em]">Connected Address: </span>
              <strong className="text-[1.1em]">{currentAddress}</strong>
            </p>
            <p>
              <span className="text-[1.3em]">Address Balance: </span>
              <strong className="text-[1.1em]">{balance} ETH</strong>
            </p>
          </div>
        ) : (
          <p className="text-gray-700">No wallet connected</p>
        )}
      </section>

      {/* Second Section: Status Boxes */}
      <section className="mb-8 grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-xl font-semibold text-gray-700 mb-2">
            Raffle Status
          </h2>
          <p className="text-gray-500">
            {!isRaffleOpen
              ? "The raffle is currently open! 🎉"
              : "The raffle is closed."}
          </p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-xl font-semibold text-gray-700 mb-2">
            Last Winner
          </h2>

          <a
            className="text-blue-500 hover:underline"
            href={getEtherScanUrl(lastWinner)}
            target="_blank"
          >
            {lastWinner
              .slice(0, 10)
              .concat("......")
              .concat(lastWinner.slice(Math.floor(lastWinner.length - 1 / 2)))}
          </a>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-xl font-semibold text-gray-700 mb-2">
            Last Raffle Date
          </h2>
          <p className="text-gray-500">{lastRaffleDate}</p>
        </div>

        <div className="bg-white p-6 rounded-lg shadow-md">
          <h2 className="text-xl font-semibold text-gray-700 mb-2">
            Prize Won
          </h2>
          <p className="text-gray-500">{rafflePrize} ETH</p>
        </div>
      </section>

      <RaffleContextProvider>
        <Controllers addNewAddress={addNewAddress} />
      </RaffleContextProvider>

      {/* Fourth Section: Participants in the Raffle */}
      {!isRaffleOpen && <ListOfParticipants addresses={addresses} />}
    </>
  );
}
