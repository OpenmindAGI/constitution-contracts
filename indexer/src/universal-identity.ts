import {
  RuleAdded as RuleAddedEvent,
  RuleRemoved as RuleRemovedEvent,
} from "../generated/UniversalIdentity/UniversalIdentity"
import { Rule } from "../generated/schema"
import { Bytes, crypto } from "@graphprotocol/graph-ts"

export function handleRuleAdded(event: RuleAddedEvent): void {
  const rule = event.params.rule;
  const ruleID = Bytes.fromHexString(crypto.keccak256(rule).toHex());
  let ruleStorage = Rule.load(ruleID);

  if (ruleStorage == null) {
    ruleStorage = new Rule(ruleID);
    ruleStorage.rule = rule;
  }

  ruleStorage.active = true;
  ruleStorage.blockNumber = event.block.number;
  ruleStorage.blockTimestamp = event.block.timestamp;
  ruleStorage.transactionHash = event.transaction.hash;

  ruleStorage.save();
}

export function handleRuleRemoved(event: RuleRemovedEvent): void {
  const rule = event.params.rule;
  const ruleID = Bytes.fromHexString(crypto.keccak256(rule).toHex());
  let ruleStorage = Rule.load(ruleID);

  if (ruleStorage == null) {
    ruleStorage = new Rule(ruleID);
    ruleStorage.rule = rule;
  }

  ruleStorage.active = false;
  ruleStorage.blockNumber = event.block.number;
  ruleStorage.blockTimestamp = event.block.timestamp;
  ruleStorage.transactionHash = event.transaction.hash;

  ruleStorage.save();
}
