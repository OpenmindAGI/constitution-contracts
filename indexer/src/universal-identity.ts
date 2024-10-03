import {
  RuleAdded as RuleAddedEvent,
  RuleRemoved as RuleRemovedEvent,
} from "../generated/UniversalIdentity/UniversalIdentity"
import { Rule } from "../generated/schema"

export function handleRuleAdded(event: RuleAddedEvent): void {
  const ruleID = event.params.rule;
  let rule = Rule.load(ruleID);

  if (rule == null) {
    rule = new Rule(ruleID);
    rule.rule = ruleID;
  }

  rule.active = true;
  rule.blockNumber = event.block.number;
  rule.blockTimestamp = event.block.timestamp;
  rule.transactionHash = event.transaction.hash;

  rule.save();
}

export function handleRuleRemoved(event: RuleRemovedEvent): void {
  const ruleID = event.params.rule;
  let rule = Rule.load(ruleID);

  if (rule == null) {
    rule = new Rule(ruleID);
    rule.rule = ruleID;
  }

  rule.active = false;
  rule.blockNumber = event.block.number;
  rule.blockTimestamp = event.block.timestamp;
  rule.transactionHash = event.transaction.hash;

  rule.save();
}
