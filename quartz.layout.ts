import { PageLayout, SharedLayout } from "./quartz/cfg"
import * as Component from "./quartz/components"

// components shared across all pages
export const sharedPageComponents: SharedLayout = {
  head: Component.Head(),
  header: [],
  afterBody: [],
  footer: Component.Footer({
    links: {
      GitHub: "https://github.com/aengu",
      Email: "mailto:shr19970923@gmail.com",
    },
  }),
}

// components for pages that display a single page (e.g. a single note)
export const defaultContentPageLayout: PageLayout = {
  beforeBody: [
    Component.ConditionalRender({
      component: Component.Breadcrumbs(),
      condition: (page) => page.fileData.slug !== "index",
    }),
    Component.ArticleTitle(),
    Component.ContentMeta(),
    Component.TagList(),
  ],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
        { Component: Component.ReaderMode() },
      ],
    }),
    Component.Explorer({
      filterFn: (node) => {
        // 최상위 항목(LearnLog, 이력서, 자기소개서)만 표시, 하위 파일 숨김
        const slug = node.slug
        const parts = slug.split("/").filter((s) => s && s !== "index")
        return parts.length <= 1
      },
      folderClickBehavior: "link",
      folderDefaultState: "collapsed",
    }),
  ],
  right: [],
}

// components for pages that display lists of pages  (e.g. tags or folders)
export const defaultListPageLayout: PageLayout = {
  beforeBody: [Component.Breadcrumbs(), Component.ArticleTitle(), Component.ContentMeta()],
  left: [
    Component.PageTitle(),
    Component.MobileOnly(Component.Spacer()),
    Component.Flex({
      components: [
        {
          Component: Component.Search(),
          grow: true,
        },
        { Component: Component.Darkmode() },
      ],
    }),
    Component.Explorer({
      filterFn: (node) => {
        // 최상위 항목(LearnLog, 이력서, 자기소개서)만 표시, 하위 파일 숨김
        const slug = node.slug
        const parts = slug.split("/").filter((s) => s && s !== "index")
        return parts.length <= 1
      },
      folderClickBehavior: "link",
      folderDefaultState: "collapsed",
    }),
  ],
  right: [],
}
