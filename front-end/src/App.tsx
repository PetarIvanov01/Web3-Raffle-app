import Layout from "./components/layout";
import RaffleContextProvider from "./providers/RaffleContextProvider";
import Web3ContextProvider from "./providers/Web3ContextProvider";

export default function App() {
  return (
    <div className="flex min-h-screen justify-center items-center">
      <div className="container p-8 bg-gray-50 rounded-lg shadow-lg">
        <section className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-gray-800">
            Welcome to the Raffle DApp
          </h1>
          <p className="text-gray-600 mt-2">
            Join the raffle to win exciting prizes! Remember, the more you
            participate, the higher your chances of winning!
          </p>
        </section>
        {window.ethereum ? (
          <Web3ContextProvider>
            <RaffleContextProvider>
              <Layout />
            </RaffleContextProvider>
          </Web3ContextProvider>
        ) : (
          <>
            <section className="mb-8 text-center bg-red-100 p-6 rounded-lg shadow-md">
              <h2 className="text-2xl font-semibold text-red-600 mb-2">
                MetaMask Not Installed
              </h2>
              <p className="text-gray-700">
                It seems that you do not have MetaMask installed. Please install
                MetaMask to participate in the raffle.
              </p>
              <a
                href="https://metamask.io/download.html"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block mt-4 px-6 py-3 bg-blue-500 text-white rounded-lg shadow-md hover:bg-blue-600"
              >
                Install MetaMask
              </a>
            </section>
          </>
        )}
      </div>
    </div>
  );
}
