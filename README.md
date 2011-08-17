# ey-cloud-recipes

This is a repository of chef recipes that I have written for EY nodes. I suggest you copy them to your own cookbooks folder and then enable them in `main/recipes/default.rb`. :)


## Installation

Follow these steps to use custom deployment recipes with your applications.

* Install the engineyard gem:
  $ gem install engineyard
* Add any custom recipes or tweaks to your copy of these recipes.
* Upload them with: `ey recipes upload`
* Run them with: `ey recipes apply`
