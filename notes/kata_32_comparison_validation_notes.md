# Kata 32: Comparison Validation

## The Concept
Propagating errors across multiple fields. The classic use case is **"Password Confirmation"**, where the validity of one field (`confirmation`) depends entirely on the value of another (`password`).

## The Elixir Way
Elixir uses **Changesets** (specifically `Ecto.Changeset`) as the gold standard for data validation. Even if you aren't using a database, you can (and should) use Changesets for UI forms.
*   **Schemaless Changesets**: You can create a changeset from a simple map types definition, without a DB schema.
*   **Atomic Validation**: A changeset captures the entire state of the form (valid? errors? changes?) in one immutable struct.

> *Note: In this specific kata, we might use manual map validation to keep it simple, but the principle mimics Changeset behavior.*

## Deep Dive

### 1. Cross-Field Validation
Validation is often thought of as "checking one field". Comparison validation requires looking at the **whole** form data.
```elixir
if data.password != data.confirmation do
  add_error(changeset, :confirmation, "does not match password")
end
```
This typically happens in the `validate` callback.

### 2. Error Tagging and Translation
Phoenix forms use a standard error tuple format: `{"Error message %{count}", [count: 3]}`. This allows for I18n (Internationalization).
When you see code like `local_translate_error`, it is converting these tuples into human-readable strings.

### 3. Real-time Feedback Loop
1.  **User Types**: `phx-change="validate"` triggers.
2.  **Server Validates**: Logic runs, errors are generated.
3.  **Assignments**: The socket is assigned the new form object including `errors`.
4.  **Re-render**: The input tags use `phx-feedback-for` (or manual logic) to show red borders and error messages instantly.

## Common Pitfalls

1.  **Validation Noise**: Showing "Password mismatch" immediately while the user is still typing the first character of the confirmation is annoying. Good UX often involves `phx-debounce` or checking `form.action` (only showing errors after an attempted submit or blur).
2.  **Security**: never rely *only* on client-side JS validation. A malicious user can bypass it. LiveView forces server-side validation by default, which is inherently more secure.
