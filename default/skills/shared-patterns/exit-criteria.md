# Universal Exit Criteria Pattern

Add this section to define clear completion:

## Definition of Done

You may ONLY claim completion when:

□ All checklist items complete
□ Verification commands run and passed
□ Output evidence included in response
□ No "should" or "probably" in message
□ State tracking shows all phases done
□ No unresolved blockers

**Incomplete checklist = not done**

Example claim structure:
```
Status: Task complete

Evidence:
- Tests: 15/15 passing [output shown above]
- Lint: No errors [output shown above]
- Build: Success [output shown above]
- All requirements met [checklist verified]

The implementation is complete and verified.
```

**Never claim done without this structure.**
