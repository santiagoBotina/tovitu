module Adoptions
  # Namespace for the deterministic, advisory adoption-policy evaluation
  # (plan 49). Evaluates structured rules over stored signals — never a
  # provider call in the request path.
  module Evaluation
    # Snapshot schema version. Bumped when the rule vocabulary or result
    # shape changes so old snapshots can be detected and re-run.
    VERSION = 1
  end
end
