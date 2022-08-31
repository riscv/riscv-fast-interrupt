# Contribution Guidelines

As an open-source project, we welcome and encourage the community to submit patches directly to the project. In our collaborative open source environment, standards and methods for submitting changes help reduce the chaos that can result from an active development community.

This document explains how to submit patches to the project so your patch will be accepted quickly in the codebase.

## Licensing

Licensing is very important to open source projects. It helps ensure the software continues to be available under the terms that the author desired.

This project uses the Creative Commons Attribution 4.0 International license, as found in the [LICENSE](https://github.com/riscv/docs-spec-template/blob/main/LICENSE) file in the project's repo.

A license tells you what rights you have as an author, as provided by the copyright holder. It is important that the contributor fully understands the licensing rights and agrees to them. Sometimes the copyright holder isn't the contributor, such as when the contributor is doing work on behalf of a company.

## Developer Certification of Origin (DCO)

To make a good faith effort to ensure licensing criteria are met, this project requires the Developer Certificate of Origin (DCO) process to be followed.

The DCO is an attestation attached to every contribution made by every author. In the commit message of the contribution (described more fully later in this document), the author simply adds a ``Signed-off-by`` statement and thereby agrees to the DCO.

When an author submits a patch, it is a commitment that the contributor has the right to submit the patch per the license. The DCO agreement is shown below and at https://developercertificate.org.

```
Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```

### DCO Sign-Off Methods

The DCO requires that a sign-off message, in the following format, appears on each commit in the pull request:

`Signed-off-by: Stephano Cetola <scetola@linuxfoundation.org>`

You are required to use your real name in the sign-off message.

The DCO text can either be manually added to your commit body, or you can add either ``-s`` or ``--signoff`` to your usual Git commit commands. If you forget to add the sign-off you can also amend a previous commit with the sign-off by running ``git commit --amend -s``. If you've pushed your changes to GitHub already you'll need to force push your branch after this with ``git push -f``.


**Note:**

The name and email address of the account you use to submit your PR must match the name and email address on the ``Signed-off-by`` line in your commit message.
