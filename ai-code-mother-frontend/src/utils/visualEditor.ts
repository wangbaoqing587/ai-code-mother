export interface ElementInfo {
  tagName: string
  id: string
  className: string
  textContent: string
  selector: string
  pagePath: string
  rect: {
    top: number
    left: number
    width: number
    height: number
  }
}

export interface VisualEditorOptions {
  onElementSelected?: (info: ElementInfo) => void
}

interface VisualEditorInstance {
  init: (iframe: HTMLIFrameElement) => void
  enableEditMode: () => void
  disableEditMode: () => void
  toggleEditMode: () => boolean
  clearSelection: () => void
  onIframeLoad: () => void
  handleIframeMessage: (event: MessageEvent) => void
  getIsEditMode: () => boolean
}

function generateEditScript() {
  return `(function () {
  if (window.__VISUAL_EDITOR_READY__) {
    window.__visualEditorSetEditMode(true);
    return;
  }

  var isEditMode = true;
  var currentHover = null;
  var currentSelected = null;

  var style = document.createElement('style');
  style.id = 'visual-edit-style';
  style.textContent = [
    '.edit-hover { outline: 2px dashed #1890ff !important; outline-offset: 2px !important; cursor: pointer !important; }',
    '.edit-selected { outline: 3px solid #52c41a !important; outline-offset: 2px !important; cursor: pointer !important; }',
  ].join('\\n');
  document.head.appendChild(style);

  function getClassName(el) {
    if (!el || !el.className) return '';
    if (typeof el.className === 'string') return el.className;
    if (typeof el.className.baseVal === 'string') return el.className.baseVal;
    return String(el.className);
  }

  function cleanClassName(el) {
    return getClassName(el)
      .split(/\\s+/)
      .filter(function (cls) {
        return cls && cls !== 'edit-hover' && cls !== 'edit-selected';
      })
      .join(' ');
  }

  function generateSelector(el) {
    var path = [];
    var cur = el;
    while (cur && cur.nodeType === 1 && cur !== document.documentElement) {
      var sel = cur.tagName.toLowerCase();
      if (cur.id) {
        sel += '#' + cur.id;
        path.unshift(sel);
        break;
      }
      var cls = cleanClassName(cur);
      if (cls) {
        sel += '.' + cls.split(/\\s+/).join('.');
      }
      var parent = cur.parentElement;
      if (parent) {
        var idx = Array.prototype.indexOf.call(parent.children, cur) + 1;
        sel += ':nth-child(' + idx + ')';
      }
      path.unshift(sel);
      cur = parent;
    }
    return path.join(' > ');
  }

  function getElementInfo(el) {
    var rect = el.getBoundingClientRect();
    return {
      tagName: el.tagName,
      id: el.id || '',
      className: cleanClassName(el),
      textContent: (el.textContent || '').trim().substring(0, 100),
      selector: generateSelector(el),
      pagePath: (window.location.pathname || '') + (window.location.search || '') + (window.location.hash || ''),
      rect: {
        top: rect.top,
        left: rect.left,
        width: rect.width,
        height: rect.height,
      },
    };
  }

  function clearHover() {
    if (currentHover) {
      currentHover.classList.remove('edit-hover');
      currentHover = null;
    }
  }

  function clearSelected() {
    if (currentSelected) {
      currentSelected.classList.remove('edit-selected');
      currentSelected = null;
    }
  }

  function clearAll() {
    clearHover();
    clearSelected();
  }

  function setEditMode(enabled) {
    isEditMode = !!enabled;
    if (!isEditMode) {
      clearAll();
    }
  }

  window.__visualEditorSetEditMode = setEditMode;

  document.addEventListener(
    'mouseover',
    function (e) {
      if (!isEditMode) return;
      var t = e.target;
      if (!t || t === document.body || t === document.documentElement) return;
      if (currentHover === t) return;
      clearHover();
      if (t !== currentSelected) {
        t.classList.add('edit-hover');
        currentHover = t;
      }
    },
    true,
  );

  document.addEventListener(
    'mouseout',
    function (e) {
      if (!isEditMode) return;
      var t = e.target;
      if (t === currentHover) {
        clearHover();
      }
    },
    true,
  );

  document.addEventListener(
    'click',
    function (e) {
      if (!isEditMode) return;
      e.preventDefault();
      e.stopPropagation();
      var t = e.target;
      if (!t || t === document.body || t === document.documentElement) return;
      clearHover();
      if (currentSelected && currentSelected !== t) {
        currentSelected.classList.remove('edit-selected');
      }
      t.classList.add('edit-selected');
      currentSelected = t;
      window.parent.postMessage(
        { type: 'ELEMENT_SELECTED', data: { elementInfo: getElementInfo(t) } },
        '*',
      );
    },
    true,
  );

  window.addEventListener('message', function (event) {
    var payload = event.data || {};
    var type = payload.type;
    if (type === 'TOGGLE_EDIT_MODE') {
      setEditMode(!!payload.editMode);
      return;
    }
    if (type === 'CLEAR_ALL_EFFECTS') {
      clearAll();
      return;
    }
    if (type === 'CLEAR_SELECTION') {
      clearSelected();
    }
  });

  window.__VISUAL_EDITOR_READY__ = true;
})();`
}

export function buildPromptWithElement(userInput: string, info: ElementInfo | null | undefined) {
  const text = userInput.trim()
  if (!info) {
    return text
  }
  return `${text}

选中元素信息：
- 标签：${info.tagName.toLowerCase()}
- 选择器：${info.selector}
- 页面路径：${info.pagePath || '无'}
- 当前内容：${info.textContent || '无'}`
}

export function createVisualEditor(options: VisualEditorOptions = {}): VisualEditorInstance {
  let iframe: HTMLIFrameElement | null = null
  let isEditMode = false

  function init(el: HTMLIFrameElement) {
    iframe = el
  }

  function sendMessageToIframe(msg: Record<string, unknown>) {
    iframe?.contentWindow?.postMessage(msg, '*')
  }

  function injectEditScript() {
    if (!iframe) {
      return
    }
    try {
      const win = iframe.contentWindow as (Window & {
        __VISUAL_EDITOR_READY__?: boolean
        __visualEditorSetEditMode?: (enabled: boolean) => void
      }) | null
      const doc = iframe.contentDocument
      if (!win || !doc) {
        return
      }
      if (win.__VISUAL_EDITOR_READY__) {
        sendMessageToIframe({ type: 'TOGGLE_EDIT_MODE', editMode: true })
        return
      }
      const script = doc.createElement('script')
      script.id = 'visual-edit-script'
      script.textContent = generateEditScript()
      doc.head.appendChild(script)
    } catch {
      // ignore cross-origin access errors
    }
  }

  function enableEditMode() {
    if (!iframe) {
      return
    }
    isEditMode = true
    setTimeout(() => {
      injectEditScript()
    }, 300)
  }

  function disableEditMode() {
    isEditMode = false
    sendMessageToIframe({ type: 'TOGGLE_EDIT_MODE', editMode: false })
    sendMessageToIframe({ type: 'CLEAR_ALL_EFFECTS' })
  }

  function toggleEditMode() {
    if (isEditMode) {
      disableEditMode()
      return false
    }
    enableEditMode()
    return true
  }

  function clearSelection() {
    sendMessageToIframe({ type: 'CLEAR_SELECTION' })
  }

  function onIframeLoad() {
    if (isEditMode) {
      setTimeout(() => {
        injectEditScript()
      }, 500)
      return
    }
    setTimeout(() => {
      sendMessageToIframe({ type: 'CLEAR_ALL_EFFECTS' })
    }, 500)
  }

  function handleIframeMessage(event: MessageEvent) {
    if (!iframe || event.source !== iframe.contentWindow) {
      return
    }
    const payload = event.data as {
      type?: string
      data?: { elementInfo?: ElementInfo }
    } | null
    if (!payload || payload.type !== 'ELEMENT_SELECTED') {
      return
    }
    const elementInfo = payload.data?.elementInfo
    if (!elementInfo || !isEditMode) {
      return
    }
    options.onElementSelected?.(elementInfo)
  }

  function getIsEditMode() {
    return isEditMode
  }

  return {
    init,
    enableEditMode,
    disableEditMode,
    toggleEditMode,
    clearSelection,
    onIframeLoad,
    handleIframeMessage,
    getIsEditMode,
  }
}
