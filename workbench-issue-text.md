@{{ lesson }}-maintainers

As I hope you are already aware, we are rolling out the new lesson infrastructure, [The Carpentries Workbench](https://carpentries.github.io/workbench/), across all of The Carpentries official lessons in early May 2023. This means that all Data Carpentry, Library Carpentry, and Software Carpentry lesson repositories will be modified to adopt the new infrastructure in the coming days.

You can follow the transition of this lesson repository at {{ url }}.

The transition has already taken place for several lessons, and so far the process has been running quite smoothly. You should see the transition take place with minimal disruption, but there are a few things that it is important for Maintainers to be aware of. 

Here is what you can expect to happen next:

1. Any open pull requests on the repository will be closed with an automated message.
2. The repository will be set to read-only mode for a brief period while the transition occurs.
3. The new repository structure and lesson site layout will then be applied.
4. To avoid anyone accidentally pushing the old commit history back to the repository, after the transition Maintainers will need to delete and replace any existing forks and local clones they have of the lesson repository, and confirm that they have done so by replying to this issue.

I will reply here before and after the transition has taken place. If you have any questions in the meantime, please reach out to the Curriculum Team by tagging us here, e.g. @{{ org }}/core-team-curriculum.

If you would like to read more about the new lesson infrastructure and the modified repository structure you can expect post-transition, I recommend [the Infrastructure episode of the Maintainer Onboarding curriculum](https://carpentries.github.io/maintainer-onboarding/05-infrastructure.html) and [the Workbench Transition Guide](https://carpentries.github.io/workbench/transition-guide.html), which includes a side-by-side comparison of various elements of the old and new infrastructures.

