import { Hono } from 'hono'
import type { Bindings } from '../../bindings.js'

export const apiRoutes = new Hono<{ Bindings: Bindings }>()

import authRoutes from './auth.js'
import expressionsRoutes from './expressions.js'
import languagesRoutes from './languages.js'
import collectionsRoutes from './collections.js'
import usersRoutes from './users.js'
import exportRoutes from './export.js'
import downloadRoutes from './download.js'
import miscRoutes from './misc.js'
import handbooksRoutes from './handbooks.js'
import expressionGroupRoutes from './expressionGroup.js'
import { imagesRoutes } from './images.js'

apiRoutes.route('/auth', authRoutes)
apiRoutes.route('/expressions', expressionsRoutes)
apiRoutes.route('/languages', languagesRoutes)
apiRoutes.route('/collections', collectionsRoutes)
apiRoutes.route('/users', usersRoutes)
apiRoutes.route('/export', exportRoutes)
apiRoutes.route('/download', downloadRoutes)
apiRoutes.route('/images', imagesRoutes)
apiRoutes.route('', miscRoutes)
apiRoutes.route('/handbooks', handbooksRoutes)
apiRoutes.route('/groups', expressionGroupRoutes)

export default apiRoutes
