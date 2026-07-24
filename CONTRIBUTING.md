# Contributing to CK-X Simulator

Contributions are welcome, whether that is a new lab, a fix to a validator that grades
something wrongly, a translation improvement, or a bug in the platform itself.

## Getting set up

Fork the repository, clone your fork, and bring the stack up:

    git clone https://github.com/<your-username>/CK-X.git
    cd CK-X
    docker compose up -d --build

Open http://localhost:30080 once the containers are healthy. Work on a branch, not on
`master`, and open a pull request against this repository when you are ready.
`docs/development-setup.md` covers the container layout if you are changing the platform
rather than the lab content.

## Do not copy real exam questions

The CNCF exams are under NDA. Do not submit questions copied or paraphrased from an exam you
have taken, from a brain dump, or from any leaked material. Write original scenarios that
exercise the same concepts. This is the one rule that will get a pull request closed without
discussion, and it protects both you and the project.

Drawing on the published curriculum, the Kubernetes documentation, or your own production
experience is fine and encouraged.

## Adding or fixing a lab

Everything that defines a lab lives under `facilitator/assets/exams`. `labs.json` is the
catalogue, and each lab is a directory such as `cka/001` containing:

    assessment.json          questions, verification mapping, translations
    config.json              worker node count, pass thresholds, answers path
    answers.md               worked solutions shown after grading
    scripts/setup/           per-question environment setup
    scripts/validation/      per-question grading

A question in `assessment.json` has an `id`, the `namespace` and `machineHostname` shown to
the candidate, the `question` body in Markdown, a list of `concepts`, and a `verification`
array. Each verification entry points at a script in `scripts/validation` and carries a
`weightage`, so a question can be partially credited. Add the lab to `labs.json` if it is new,
then run `python3 scripts/gen-index.py` to refresh the index and question counts.

Validation scripts are plain shell. Exit 0 to pass, non-zero to fail. Whatever the script
prints on failure is shown to the candidate as the reason it did not pass, so write a message
that says what was missing rather than letting it fail silently.

Setup scripts run before the lab starts and must be named `qN_..._setup.sh`. The runtime only
executes files matching that pattern, so a differently named script is ignored without any
error. Setup and validation both run on the exam machine, which is the same host the questions
tell candidates to use, so anything that touches the filesystem has to happen there to be
visible to the grader.

Three mistakes account for most broken labs, so they are worth checking before you submit.
First, make sure the validator is capable of failing: a bare `kubectl get ... | jq
'select(...)'` exits 0 even when nothing matches, which silently awards full marks, so use
`jq -e`. Second, check the task is satisfiable in this environment, for example that a
`required` pod anti-affinity rule does not ask for more nodes than `workerNodes` provides.
Third, remember this is k3s inside Docker: flannel does not enforce NetworkPolicy, so grade
those on the policy spec, and anything needing node-level access such as etcd or kubeadm has
to be graded on the command the candidate writes.
`facilitator/assets/exams/READINESS.md` documents where the simulator diverges from a real
exam cluster.

Answers in `answers.md` should follow the exam workflow rather than dumping YAML: reach for an
imperative `kubectl` command where one exists, and where it does not, generate a skeleton with
`--dry-run=client -o yaml` and edit it. That is what candidates need to practise.

Run the linter before opening a pull request:

    python3 scripts/lint-exams.py

It verifies that every referenced validation script exists, that no validator can pass
unconditionally, that setup scripts match the naming pattern, and that shell syntax and line
endings are clean. It must report zero errors. Then actually run the lab end to end, because
the linter cannot tell whether a task is solvable on a live cluster.

## Translations

Translations sit alongside the source text rather than in separate catalogue files. Interface
strings are in `app/public/js/i18n.js`, which holds an English and a Georgian dictionary that
must contain identical keys, otherwise the interface silently falls back to English. Lab names
and descriptions use `name_ka` and `description_ka` in `labs.json`, and question text uses
`question_ka` in each `assessment.json`.

Leave anything the candidate has to type or match exactly in English: resource names,
namespaces, images, API fields, flags, paths and commands. Translate the prose around them.
Adding a language means adding a dictionary in `i18n.js`, a matching `question_<code>` field,
and the language to the switcher.

## Code and commits

Match the style already in the file you are editing. Keep pull requests focused on one thing,
write commit messages that say what changed and why, and update the documentation in the same
pull request when behaviour changes. If you fix something subtle, leave a comment explaining
the reasoning, since most of the hard bugs in this project have been non-obvious.

## Reporting problems

Open an issue with enough detail to reproduce it. For a grading problem, name the lab and
question number and say what you did and what the result said. For a platform problem, include
the relevant output of `docker compose logs <service>` and your OS and Docker version.

## License

This project is distributed under the Business Source License 1.1. By contributing, you agree
that your contributions are licensed under the same terms. See `LICENSE` and `NOTICE`.
