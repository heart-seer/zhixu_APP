abstract final class ApiEndpoints {
  static const sendCode = '/auth/code';
  static const loginByCode = '/auth/login/code';
  static const register = '/auth/register';
  static const loginByPassword = '/auth/login/password';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';

  static const me = '/me';
  static const preferences = '/me/preferences';

  static const tasks = '/tasks';
  static const events = '/calendar/events';
  static const messages = '/messages';
  static const importMessage = '/messages/import';

  static String task(String id) => '/tasks/$id';
  static String taskCompletion(String id) => '/tasks/$id/completion';
  static String taskSteps(String id) => '/tasks/$id/steps';
  static String stepCompletion(String id, String stepId) =>
      '/tasks/$id/steps/$stepId/completion';
  static String step(String id, String stepId) => '/tasks/$id/steps/$stepId';
  static String timeBlocks(String id) => '/tasks/$id/time-blocks';

  static String event(String id) => '/calendar/events/$id';
  static String eventCompletion(String id) => '/calendar/events/$id/completion';

  static String message(String id) => '/messages/$id';
  static String messageRead(String id) => '/messages/$id/read';
  static String messageDraft(String id) => '/messages/$id/drafts/task';
  static String confirmDraft(String id) => '/extraction-drafts/$id/confirm';
}
