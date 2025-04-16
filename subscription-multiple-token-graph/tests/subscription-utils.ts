import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  BlacklistUpdated,
  BuyEnableUpdated,
  OwnershipTransferStarted,
  OwnershipTransferred,
  SignerUpdated,
  Subscribed,
  SubscriptionFeeUpdated,
  TokenDataAdded,
  TokensAccessUpdated,
  fundsWalletUpdated
} from "../generated/Subscription/Subscription"

export function createBlacklistUpdatedEvent(
  which: Address,
  accessNow: boolean
): BlacklistUpdated {
  let blacklistUpdatedEvent = changetype<BlacklistUpdated>(newMockEvent())

  blacklistUpdatedEvent.parameters = new Array()

  blacklistUpdatedEvent.parameters.push(
    new ethereum.EventParam("which", ethereum.Value.fromAddress(which))
  )
  blacklistUpdatedEvent.parameters.push(
    new ethereum.EventParam("accessNow", ethereum.Value.fromBoolean(accessNow))
  )

  return blacklistUpdatedEvent
}

export function createBuyEnableUpdatedEvent(
  oldAccess: boolean,
  newAccess: boolean
): BuyEnableUpdated {
  let buyEnableUpdatedEvent = changetype<BuyEnableUpdated>(newMockEvent())

  buyEnableUpdatedEvent.parameters = new Array()

  buyEnableUpdatedEvent.parameters.push(
    new ethereum.EventParam("oldAccess", ethereum.Value.fromBoolean(oldAccess))
  )
  buyEnableUpdatedEvent.parameters.push(
    new ethereum.EventParam("newAccess", ethereum.Value.fromBoolean(newAccess))
  )

  return buyEnableUpdatedEvent
}

export function createOwnershipTransferStartedEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferStarted {
  let ownershipTransferStartedEvent = changetype<OwnershipTransferStarted>(
    newMockEvent()
  )

  ownershipTransferStartedEvent.parameters = new Array()

  ownershipTransferStartedEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferStartedEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferStartedEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent = changetype<OwnershipTransferred>(
    newMockEvent()
  )

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createSignerUpdatedEvent(
  oldSigner: Address,
  newSigner: Address
): SignerUpdated {
  let signerUpdatedEvent = changetype<SignerUpdated>(newMockEvent())

  signerUpdatedEvent.parameters = new Array()

  signerUpdatedEvent.parameters.push(
    new ethereum.EventParam("oldSigner", ethereum.Value.fromAddress(oldSigner))
  )
  signerUpdatedEvent.parameters.push(
    new ethereum.EventParam("newSigner", ethereum.Value.fromAddress(newSigner))
  )

  return signerUpdatedEvent
}

export function createSubscribedEvent(
  token: Address,
  tokenPrice: BigInt,
  by: Address,
  amountPurchased: BigInt,
  endTime: BigInt
): Subscribed {
  let subscribedEvent = changetype<Subscribed>(newMockEvent())

  subscribedEvent.parameters = new Array()

  subscribedEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  subscribedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenPrice",
      ethereum.Value.fromUnsignedBigInt(tokenPrice)
    )
  )
  subscribedEvent.parameters.push(
    new ethereum.EventParam("by", ethereum.Value.fromAddress(by))
  )
  subscribedEvent.parameters.push(
    new ethereum.EventParam(
      "amountPurchased",
      ethereum.Value.fromUnsignedBigInt(amountPurchased)
    )
  )
  subscribedEvent.parameters.push(
    new ethereum.EventParam(
      "endTime",
      ethereum.Value.fromUnsignedBigInt(endTime)
    )
  )

  return subscribedEvent
}

export function createSubscriptionFeeUpdatedEvent(
  oldFee: BigInt,
  newFee: BigInt
): SubscriptionFeeUpdated {
  let subscriptionFeeUpdatedEvent = changetype<SubscriptionFeeUpdated>(
    newMockEvent()
  )

  subscriptionFeeUpdatedEvent.parameters = new Array()

  subscriptionFeeUpdatedEvent.parameters.push(
    new ethereum.EventParam("oldFee", ethereum.Value.fromUnsignedBigInt(oldFee))
  )
  subscriptionFeeUpdatedEvent.parameters.push(
    new ethereum.EventParam("newFee", ethereum.Value.fromUnsignedBigInt(newFee))
  )

  return subscriptionFeeUpdatedEvent
}

export function createTokenDataAddedEvent(
  token: Address,
  data: ethereum.Tuple
): TokenDataAdded {
  let tokenDataAddedEvent = changetype<TokenDataAdded>(newMockEvent())

  tokenDataAddedEvent.parameters = new Array()

  tokenDataAddedEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  tokenDataAddedEvent.parameters.push(
    new ethereum.EventParam("data", ethereum.Value.fromTuple(data))
  )

  return tokenDataAddedEvent
}

export function createTokensAccessUpdatedEvent(
  token: Address,
  access: boolean
): TokensAccessUpdated {
  let tokensAccessUpdatedEvent = changetype<TokensAccessUpdated>(newMockEvent())

  tokensAccessUpdatedEvent.parameters = new Array()

  tokensAccessUpdatedEvent.parameters.push(
    new ethereum.EventParam("token", ethereum.Value.fromAddress(token))
  )
  tokensAccessUpdatedEvent.parameters.push(
    new ethereum.EventParam("access", ethereum.Value.fromBoolean(access))
  )

  return tokensAccessUpdatedEvent
}

export function createfundsWalletUpdatedEvent(
  oldfundsWallet: Address,
  newfundsWallet: Address
): fundsWalletUpdated {
  let fundsWalletUpdatedEvent = changetype<fundsWalletUpdated>(newMockEvent())

  fundsWalletUpdatedEvent.parameters = new Array()

  fundsWalletUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldfundsWallet",
      ethereum.Value.fromAddress(oldfundsWallet)
    )
  )
  fundsWalletUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newfundsWallet",
      ethereum.Value.fromAddress(newfundsWallet)
    )
  )

  return fundsWalletUpdatedEvent
}
