#include <node_api.h>
#include <stdint.h>
#include <vector>

extern "C" {
  uintptr_t macplay_window(double aspect);
  void macplay_configure_window(double width, double height, double panel_width, double panel_height, bool fullscreen, bool strict);
  void macplay_pump();
  void macplay_select_display(uint32_t id);
  void macplay_close_window();
  int macplay_input(double *x, double *y, int *down);
}

static napi_value SelectDisplayOptions(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value argv[1];
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  uint32_t id = 0;
  if (argc >= 1) {
    napi_get_value_uint32(env, argv[0], &id);
  }
  macplay_select_display(id);
  napi_value undefined;
  napi_get_undefined(env, &undefined);
  return undefined;
}

static napi_value ConfigureWindowOptions(napi_env env, napi_callback_info info) {
  size_t argc = 6;
  napi_value argv[6];
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  double width = 1920, height = 1080, panel_w = 1920, panel_h = 1080;
  bool fullscreen = false, strict = false;
  if (argc >= 1) napi_get_value_double(env, argv[0], &width);
  if (argc >= 2) napi_get_value_double(env, argv[1], &height);
  if (argc >= 3) napi_get_value_double(env, argv[2], &panel_w);
  if (argc >= 4) napi_get_value_double(env, argv[3], &panel_h);
  if (argc >= 5) napi_get_value_bool(env, argv[4], &fullscreen);
  if (argc >= 6) napi_get_value_bool(env, argv[5], &strict);
  macplay_configure_window(width, height, panel_w, panel_h, fullscreen, strict);
  napi_value undefined;
  napi_get_undefined(env, &undefined);
  return undefined;
}

static napi_value WindowHandle(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value argv[1];
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  double aspect = 16.0 / 9.0;
  if (argc >= 1) {
    napi_get_value_double(env, argv[0], &aspect);
  }
  uintptr_t handle = macplay_window(aspect);
  napi_value buffer;
  void* data = nullptr;
  napi_create_buffer_copy(env, sizeof(uintptr_t), (const void*)&handle, &data, &buffer);
  return buffer;
}

static napi_value CloseVideoWindow(napi_env env, napi_callback_info info) {
  macplay_close_window();
  napi_value undefined;
  napi_get_undefined(env, &undefined);
  return undefined;
}

static napi_value PumpEvents(napi_env env, napi_callback_info info) {
  macplay_pump();
  std::vector<double> out;
  double x = 0.0, y = 0.0;
  int down = 0;
  while (macplay_input(&x, &y, &down) != 0) {
    out.push_back(x);
    out.push_back(y);
    out.push_back((double)down);
  }
  napi_value array;
  napi_create_array_with_length(env, out.size(), &array);
  for (size_t i = 0; i < out.size(); ++i) {
    napi_value val;
    napi_create_double(env, out[i], &val);
    napi_set_element(env, array, i, val);
  }
  return array;
}

#define EXPORT_FUNC(name, fn) \
  do { \
    napi_value fn_val; \
    napi_create_function(env, name, NAPI_AUTO_LENGTH, fn, nullptr, &fn_val); \
    napi_set_named_property(env, exports, name, fn_val); \
  } while (0)

static napi_value Init(napi_env env, napi_value exports) {
  EXPORT_FUNC("macplaySelectDisplayOptions", SelectDisplayOptions);
  EXPORT_FUNC("macplayConfigureWindowOptions", ConfigureWindowOptions);
  EXPORT_FUNC("macplayWindowHandle", WindowHandle);
  EXPORT_FUNC("macplayCloseVideoWindow", CloseVideoWindow);
  EXPORT_FUNC("macplayPumpEvents", PumpEvents);
  return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
