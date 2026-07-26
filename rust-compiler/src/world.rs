use typst::foundations::{Bytes, Datetime};
use typst::text::{Font, FontBook};
use typst::Library;
use typst::syntax::{FileId, Source};
use typst::diag::FileResult;

pub struct SingleSourceWorld {
    source:     Source,
    library:    typst::utils::LazyHash<Library>,
    book:       typst::utils::LazyHash<FontBook>,
    fonts:      Vec<Font>,
    assets_dir: Option<std::path::PathBuf>,
}

impl SingleSourceWorld {
    pub fn new(typ_source: String) -> Self {
        let assets_dir = std::env::var("TYPST_ASSETS_DIR")
            .ok()
            .map(std::path::PathBuf::from);

        let fonts: Vec<Font> = typst_assets::fonts()
            .flat_map(|data| {
                let bytes = Bytes::from_static(data);
                Font::iter(bytes)
            })
            .collect();

        let book = FontBook::from_fonts(&fonts);

        Self {
            source:  Source::detached(typ_source),
            library: typst::utils::LazyHash::new(Library::default()),
            book:    typst::utils::LazyHash::new(book),
            fonts,
            assets_dir,
        }
    }
}

impl typst::World for SingleSourceWorld {
    fn library(&self) -> &typst::utils::LazyHash<Library> {
        &self.library
    }

    fn book(&self) -> &typst::utils::LazyHash<FontBook> {
        &self.book
    }

    fn main(&self) -> FileId {
        self.source.id()
    }

    fn source(&self, id: FileId) -> FileResult<Source> {
        if id == self.source.id() {
            Ok(self.source.clone())
        } else {
            Err(typst::diag::FileError::NotFound(id.vpath().as_rootless_path().into()))
        }
    }

    fn file(&self, id: FileId) -> FileResult<Bytes> {
        let rel = id.vpath().as_rootless_path();
        if let Some(ref assets_dir) = self.assets_dir {
            let full_path = assets_dir.join(rel);
            match std::fs::read(&full_path) {
                Ok(data) => return Ok(Bytes::from(data)),
                Err(_) => {}
            }
        }
        Err(typst::diag::FileError::NotFound(rel.into()))
    }

    fn font(&self, index: usize) -> Option<Font> {
        self.fonts.get(index).cloned()
    }

    fn today(&self, _offset: Option<i64>) -> Option<Datetime> {
        None
    }
}
