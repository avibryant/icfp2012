Quick summary of Monte Carlo Tree Search:

- Build a tree, with a node for each game state. The root is the initial state.
- Each time through, the algorithm:
  - First, select a leaf. Starting at the root:
     - If there are new children you can create (moves you haven't tried), pick the best
     move and create a child for that, and use that as your leaf.
     - Otherwise, look through all your children and pick the highest potential one,
     then recurse. (See below for what "potential means")
  - Then, starting from the game state represented by the leaf, try playing out a game until
  completion (or you hit some max depth and abort). Use a randomized algorithm to do this.
  - Walk back up the tree from the leaf to the root, and update each of those nodes with the results of the trial. What we're tracking is the number of tries and the average score.
  - The number of tries and average score gives us an upper bound on how good we think this node could be. If we haven't tried it much or we've gotten high scores, it has high potential. If we've tried it lots and gotten low scores, it has low potential.
  - Separately, keep track of the best trial result we've ever seen. At any point, we can give that as our solution.