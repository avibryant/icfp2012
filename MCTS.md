Quick summary of Monte Carlo Tree Search:

- Build a tree, with a node for each game state. The root is the initial state.
- Each time through:
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

  Some refinements:
  - if we ever find a winning solution, we try compacting it: test omitting any one move and see if it still wins without that move. If it does, recurse. This gets rid of a lot of spurious Wait moves etc.
  - instead of just growing the tree as part of the leaf selection process, which happens slowly and breadth-first, also grow it with the results of the trials (so you'll shoot off a deep single-strand branch). I've seen some evidence that it performs better this way, but at a memory cost.

 Parameters:
  The better the randomized algorithm you use to play out games from the leaves, the better the results will be. This will have the biggest overall effect, but it's a trade off with speed: the slower this is the fewer trials we get to run. If you use a pure random strategy, the solutions tend to get dominated by "find the first lambda or two and abort".

  There are a couple of constants (C and D) that control how much we explore new children vs. exploiting the ones we already know are decent and can be tweaked.

  There's a max depth that controls how far to simulate before aborting. One heuristic that seems to work ok here is number of lambdas * 5.