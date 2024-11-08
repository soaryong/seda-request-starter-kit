import {
  Bytes,
  Console,
  Process,
  httpFetch,
  u128,
} from "@seda-protocol/as-sdk/assembly";

// API response structure for the price feed
@json
class RankingFeedResponse {
  message!: string;
}

/**
 * Executes the data request phase within the SEDA network.
 * This phase is responsible for fetching non-deterministic data (e.g., price of an asset pair)
 * from an external source such as a price feed API. The input specifies the asset pair to fetch.
 */
export function executionPhase(): void {
  // Retrieve the input parameters for the data request (DR).
  // Expected to be in the format "symbolA-symbolB" (e.g., "BTC-USDT").
  const drInputsRaw = Process.getInputs().toUtf8String();
  console.log(drInputsRaw);
  // Log the asset pair being fetched as part of the Execution Standard Out.
  Console.log(`Fetching price for pair: ${drInputsRaw}`);

  // Split the input string into symbolA and symbolB.
  // Example: "ETH-USDC" will be split into "ETH" and "USDC".
  //const drInputs = drInputsRaw.split("-");
  //const symbolA = drInputs[0];
  //const symbolB = drInputs[1];

  // Make an HTTP request to a price feed API to get the price for the symbol pair.
  // The URL is dynamically constructed using the provided symbols (e.g., ETHUSDC).
  const response = httpFetch(`${process.env.RANK_API_URL}/${drInputsRaw}`);

  // Check if the HTTP request was successfully fulfilled.
  if (!response.ok) {
    // Handle the case where the HTTP request failed or was rejected.
    Console.error(
      `HTTP Response was rejected: ${response.status.toString()} - ${response.bytes.toUtf8String()}`
    );
    // Report the failure to the SEDA network with an error code of 1.
    Process.error(Bytes.fromUtf8String("Error while fetching price feed"));
  }

  // Parse the API response as defined earlier.
  const data = response.bytes.toJSON<RankingFeedResponse>();

  // Convert to integer (and multiply by 1e6 to avoid losing precision).
  const message = data.message;
  if (!message) {
    // Report the failure to the SEDA network with an error code of 1.
    Process.error(
      Bytes.fromUtf8String(`Error while parsing price data: ${data.message}`)
    );
  }

  const result = u128.from(message);

  // Report the successful result back to the SEDA network.
  Process.success(Bytes.fromNumber<u128>(result));
}
